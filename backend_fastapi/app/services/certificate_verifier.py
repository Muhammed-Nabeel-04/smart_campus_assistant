# File: app/services/certificate_verifier.py
# ─────────────────────────────────────────────────────────────────────────────
# Option B — Smart Rule-Based Certificate Verification
# OCR (pytesseract) + pattern matching
# No AI API needed — works fully offline
#
# Flow:
#   1. Decode base64 file
#   2. Extract text via OCR (image) or pdfplumber (PDF)
#   3. Run rule checks: name, platform, date, course
#   4. Return: valid | review | invalid + details
# ─────────────────────────────────────────────────────────────────────────────

import base64
import io
import re
import json
from datetime import datetime
from typing import Optional
import pytesseract
pytesseract.pytesseract.tesseract_cmd = r'E:\1 MyApps\tesseract.exe'



# ── Try to import OCR dependencies (graceful fallback if missing) ─────────────
try:
    from PIL import Image
    import pytesseract
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False

try:
    import pdfplumber
    PDF_AVAILABLE = True
except ImportError:
    PDF_AVAILABLE = False


# ── Known trusted platforms per criterion ─────────────────────────────────────
PLATFORM_KEYWORDS = {
    "2_1_nptel": [
        "nptel", "swayam", "iit", "iim", "noc", "national programme",
        "technology enhanced learning", "elite", "gold", "silver", "topper"
    ],
    "2_2_online_cert": [
        "coursera", "udemy", "edx", "linkedin learning", "udacity",
        "google", "microsoft", "aws", "oracle", "cisco", "ibm",
        "infosys springboard", "simplilearn", "great learning", "internshala"
    ],
    "2_3_internship": [
        "internship", "in-plant training", "industrial training",
        "offer letter", "completion certificate", "training certificate",
        "company", "pvt", "ltd", "technologies", "solutions", "systems",
        "engineering", "intern", "trainee"
    ],
    "2_4_competition": [
        "hackathon", "winner", "first prize", "second prize", "third prize",
        "top 3", "finalist", "participation", "certificate of merit",
        "competition", "contest", "coding", "smart india", "technofest",
        "techfest", "ieee", "iste", "acm"
    ],
    "2_5_publication": [
        "published", "patent", "journal", "conference", "proceedings",
        "paper", "research", "issn", "isbn", "doi", "elsevier", "springer",
        "ieee xplore", "scopus", "ugc"
    ],
    "1_6_project": [
        "project", "completion", "developed", "implemented", "certificate",
        "acknowledgement", "report"
    ],
}

# Certificate words that should appear in ANY valid certificate
GENERIC_CERT_KEYWORDS = [
    "certificate", "certify", "awarded", "completed", "successfully",
    "achievement", "participation", "this is to certify", "has successfully",
    "presented to", "in recognition"
]

# Date patterns
DATE_PATTERNS = [
    r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+\d{4}\b',
    r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b',
    r'\b\d{4}\b',  # Just a year
]


# ── Main extraction function ───────────────────────────────────────────────────

def extract_text_from_file(file_data_b64: str, file_type: str) -> str:
    """Extract text from base64-encoded image or PDF."""
    try:
        raw_bytes = base64.b64decode(file_data_b64)
    except Exception:
        return ""

    text = ""

    if file_type == "pdf" and PDF_AVAILABLE:
        try:
            with pdfplumber.open(io.BytesIO(raw_bytes)) as pdf:
                for page in pdf.pages[:3]:  # First 3 pages max
                    page_text = page.extract_text() or ""
                    text += page_text + "\n"
        except Exception:
            # PDF extraction failed — try OCR on first page image
            pass

    if file_type == "image" and OCR_AVAILABLE:
        try:
            img = Image.open(io.BytesIO(raw_bytes))
            # Enhance image for better OCR
            img = img.convert("L")  # Grayscale
            text = pytesseract.image_to_string(img, config="--psm 6")
        except Exception:
            pass

    # If PDF OCR failed or not available, try image OCR on PDF-converted
    if not text.strip() and OCR_AVAILABLE and file_type == "pdf":
        try:
            # Try treating as image directly
            img = Image.open(io.BytesIO(raw_bytes))
            text = pytesseract.image_to_string(img)
        except Exception:
            pass

    return text.strip()


# ── Rule-based verification ────────────────────────────────────────────────────

def verify_certificate(
    ocr_text: str,
    criterion_key: str,
    student_name: Optional[str] = None,
) -> dict:
    """
    Run rule-based checks on extracted OCR text.

    Returns:
        {
            "status": "valid" | "review" | "invalid",
            "score": 0-100,
            "checks": { ... },
            "details": "Human readable summary"
        }
    """
    if not ocr_text or len(ocr_text.strip()) < 20:
        return {
            "status": "review",
            "score": 30,
            "checks": {
                "text_extracted": False,
                "has_cert_word": False,
                "has_platform": False,
                "has_name": False,
                "has_date": False,
            },
            "details": "Could not extract enough text from the file. Please upload a clearer image.",
        }

    text_lower = ocr_text.lower()
    checks = {}
    score = 0

    # ── Check 1: Is it a certificate? (generic cert words) ──────────────
    has_cert = any(kw in text_lower for kw in GENERIC_CERT_KEYWORDS)
    checks["has_cert_word"] = has_cert
    checks["text_extracted"] = True
    if has_cert:
        score += 30

    # ── Check 2: Platform/Organization keywords ──────────────────────────
    platform_keys = PLATFORM_KEYWORDS.get(criterion_key, [])
    found_platforms = [kw for kw in platform_keys if kw in text_lower]
    has_platform = len(found_platforms) > 0
    checks["has_platform"] = has_platform
    checks["found_platforms"] = found_platforms[:3]  # show first 3 matches
    if has_platform:
        score += 35

    # ── Check 3: Student name match ──────────────────────────────────────
    has_name = False
    if student_name:
        # Check first name, last name, and full name
        name_parts = student_name.lower().split()
        name_matches = sum(1 for part in name_parts if len(part) > 2 and part in text_lower)
        has_name = name_matches >= 1  # At least one name part found
    checks["has_name"] = has_name
    if has_name:
        score += 20
    elif not student_name:
        # No name to check — give benefit of doubt
        score += 10

    # ── Check 4: Date presence ───────────────────────────────────────────
    has_date = any(re.search(pat, text_lower, re.IGNORECASE) for pat in DATE_PATTERNS)
    checks["has_date"] = has_date
    if has_date:
        score += 15

    # ── Check 5: Minimum text length (quality check) ─────────────────────
    checks["text_length"] = len(ocr_text)
    if len(ocr_text) > 100:
        score += 10  # Bonus for rich text (proper scanned cert)
        checks["text_quality"] = "good"
    else:
        checks["text_quality"] = "low"

    score = min(score, 100)

    # ── Final decision ────────────────────────────────────────────────────
    if score >= 70:
        status = "valid"
        details = _build_details(checks, found_platforms, "Certificate looks valid.")
    elif score >= 40:
        status = "review"
        details = _build_details(checks, found_platforms,
            "Certificate needs manual review — some details could not be confirmed.")
    else:
        status = "invalid"
        details = _build_details(checks, found_platforms,
            "Certificate appears invalid or unclear. Please upload a proper certificate image.")

    return {
        "status": status,
        "score": score,
        "checks": checks,
        "details": details,
    }


def _build_details(checks: dict, found_platforms: list, summary: str) -> str:
    lines = [summary]
    if not checks.get("has_cert_word"):
        lines.append("⚠ Certificate keyword not found.")
    if not checks.get("has_platform"):
        lines.append("⚠ Platform/organization not recognized.")
    if checks.get("has_platform") and found_platforms:
        lines.append(f"✓ Recognized: {', '.join(found_platforms)}")
    if not checks.get("has_name"):
        lines.append("⚠ Student name not clearly visible.")
    if not checks.get("has_date"):
        lines.append("⚠ No date found on certificate.")
    if checks.get("text_quality") == "low":
        lines.append("⚠ Low text quality — consider uploading a higher resolution image.")
    return " | ".join(lines)


# ── Full pipeline: decode → OCR → verify ─────────────────────────────────────

def process_certificate(
    file_data_b64: str,
    file_type: str,
    criterion_key: str,
    student_name: Optional[str] = None,
) -> dict:
    """Full pipeline — call this from the route."""
    ocr_text = extract_text_from_file(file_data_b64, file_type)
    result = verify_certificate(ocr_text, criterion_key, student_name)
    result["ocr_text"] = ocr_text[:2000] if ocr_text else ""  # Store first 2000 chars
    return result
