# File: app/services/ssm_scoring.py
# ─────────────────────────────────────────────────────────────────────────────
# SSM Scoring Engine — activity-based
# Score recalculates from all entries every time an entry is added/removed
# Total: 500 pts (5 categories × 100 pts each)
# ─────────────────────────────────────────────────────────────────────────────

import json
from typing import List
from app.models.ssm import SSMEntry, SSMMentorInput


# ── Entry type configuration ──────────────────────────────────────────────────
# For each entry_type: max_count (how many count), score_map
# score_map: detail_key → value → points

ENTRY_CONFIG = {

    # ── CATEGORY 1: Academic Performance ─────────────────────────────────────

    "iat_gpa": {
        "category": 1,
        "label": "Internal Assessment GPA",
        "max_count": 1,
        "proof_required": False,
        "score_fn": lambda d: (
            15 if (d.get("gpa") or 0) >= 9 else
            10 if (d.get("gpa") or 0) >= 8 else
            5  if (d.get("gpa") or 0) >= 7 else 0
        ),
    },
    "university_gpa": {
        "category": 1,
        "label": "University Exam GPA",
        "max_count": 1,
        "proof_required": False,
        "score_fn": lambda d: (
            15 if (d.get("gpa") or 0) >= 9 else
            10 if (d.get("gpa") or 0) >= 8 else
            5  if (d.get("gpa") or 0) >= 7 else 0
        ),
    },
    "attendance": {
        "category": 1,
        "label": "Attendance & Academic Discipline",
        "max_count": 1,
        "proof_required": False,
        "score_fn": lambda d: (
            15 if (d.get("percentage") or 0) >= 95 else
            10 if (d.get("percentage") or 0) >= 90 else
            5  if (d.get("percentage") or 0) >= 85 else 0
        ),
    },
    "project": {
        "category": 1,
        "label": "Project (Beyond Curriculum)",
        "max_count": 1,
        "proof_required": True,
        "score_fn": lambda d: (
            15 if d.get("status") == "Fully Completed" else
            10 if d.get("status") == "Partial" else
            5  if d.get("status") == "Concept" else 0
        ),
    },
    "consistency_index": {
        "category": 1,
        "label": "Academic Consistency Index",
        "max_count": 1,
        "proof_required": False,
        "score_fn": lambda d: (
            15 if (d.get("percentage") or 0) >= 95 else
            10 if (d.get("percentage") or 0) >= 90 else
            5  if (d.get("percentage") or 0) >= 85 else 0
        ),
    },

    # ── CATEGORY 2: Student Development ──────────────────────────────────────

    "nptel": {
        "category": 2,
        "label": "NPTEL / SWAYAM Certificate",
        "max_count": 1,   # only the best one counts
        "proof_required": True,
        "score_fn": lambda d: (
            20 if d.get("level") in ["Elite+Silver", "Elite+Gold", "Top5%"] else
            15 if d.get("level") == "Elite" else
            10 if d.get("level") == "Completed" else
            5  if d.get("level") == "Participated" else 0
        ),
    },
    "online_cert": {
        "category": 2,
        "label": "Industry Online Certification",
        "max_count": 99,   # count all, score based on total count
        "proof_required": True,
        "score_fn": lambda d: 5,   # 5 per cert, capped at category level
        # Note: category cap handles max
    },
    "internship": {
        "category": 2,
        "label": "Internship / In-plant Training",
        "max_count": 1,
        "proof_required": True,
        "score_fn": lambda d: (
            20 if d.get("duration") == "4weeks+" else
            15 if d.get("duration") == "2-4weeks" else
            10 if d.get("duration") == "1-2weeks" else
            5  if d.get("duration") == "Participation" else 0
        ),
    },
    "competition": {
        "category": 2,
        "label": "Technical Competition / Hackathon",
        "max_count": 1,   # best result counts
        "proof_required": True,
        "score_fn": lambda d: (
            20 if d.get("result") == "Winner" else
            10 if d.get("result") == "Finalist" else
            5  if d.get("result") == "Participation" else 0
        ),
    },
    "publication": {
        "category": 2,
        "label": "Publication / Patent / Product",
        "max_count": 1,
        "proof_required": True,
        "score_fn": lambda d: (
            15 if d.get("type") == "Patent" else
            10 if d.get("type") == "Conference" else
            5  if d.get("type") == "Prototype" else 0
        ),
    },
    "skill_program": {
        "category": 2,
        "label": "Professional Skill Development",
        "max_count": 99,   # count all
        "proof_required": True,
        "score_fn": lambda d: 5,   # 5 per program, capped
    },

    # ── CATEGORY 3: Skill & Readiness ────────────────────────────────────────

    "placement_readiness": {
        "category": 3,
        "label": "Placement Readiness & Training",
        "max_count": 1,
        "proof_required": False,
        "score_fn": lambda d: (
            20 if (d.get("percentage") or 0) >= 95 else
            10 if (d.get("percentage") or 0) >= 80 else
            5  if (d.get("percentage") or 0) >= 75 else 0
        ),
    },
    "industry_interaction": {
        "category": 3,
        "label": "Industry Interaction",
        "max_count": 99,   # count all
        "proof_required": False,
        "score_fn": lambda d: 5,   # per interaction, capped
    },
    "research_paper": {
        "category": 3,
        "label": "Research Paper Reading",
        "max_count": 99,
        "proof_required": False,
        "score_fn": lambda d: 5,
    },
    "innovation": {
        "category": 3,
        "label": "Innovation / Idea Contribution",
        "max_count": 1,
        "proof_required": False,
        "score_fn": lambda d: (
            10 if d.get("level") == "Implemented" else
            5  if d.get("level") == "Proposed" else 0
        ),
    },

    # ── CATEGORY 5: Leadership ────────────────────────────────────────────────

    "leadership_role": {
        "category": 5,
        "label": "Formal Leadership Role",
        "max_count": 1,
        "proof_required": False,
        "score_fn": lambda d: (
            15 if d.get("level") == "College" else
            10 if d.get("level") == "Department" else
            5  if d.get("level") == "Class" else 0
        ),
    },
    "event_leadership": {
        "category": 5,
        "label": "Event Leadership",
        "max_count": 99,  # count events led
        "proof_required": False,
        "score_fn": lambda d: 7,  # per event led
    },
    "team_management": {
        "category": 5,
        "label": "Team Management",
        "max_count": 1,
        "proof_required": False,
        "score_fn": lambda d: (
            15 if d.get("level") == "Excellent" else
            10 if d.get("level") == "Good" else
            5  if d.get("level") == "Limited" else 0
        ),
    },
    "innovation_initiative": {
        "category": 5,
        "label": "Innovation & Initiative",
        "max_count": 1,
        "proof_required": False,
        "score_fn": lambda d: (
            25 if d.get("level") == "Implemented" else
            15 if d.get("level") == "Proposed" else
            5  if d.get("level") == "Minor" else 0
        ),
    },
    "community_leadership": {
        "category": 5,
        "label": "Social / Community Leadership",
        "max_count": 1,
        "proof_required": False,
        "score_fn": lambda d: (
            25 if d.get("level") == "Led" else
            15 if d.get("level") == "Active" else
            5  if d.get("level") == "Minimal" else 0
        ),
    },
}

# Category 4 is fully mentor-evaluated — no student entries


def score_entry(entry_type: str, details: dict) -> float:
    """Calculate score for a single entry."""
    config = ENTRY_CONFIG.get(entry_type)
    if not config:
        return 0.0
    try:
        return float(config["score_fn"](details))
    except Exception:
        return 0.0


def calculate_full_score(
    entries: List[SSMEntry],
    mentor_input: SSMMentorInput = None,
) -> dict:
    """
    Recalculate total score from all entries + mentor input.
    Returns full breakdown dict.
    """

    # ── Category 1: Academic ──────────────────────────────────────────────────
    c1 = 0
    c1_breakdown = {}

    for e in entries:
        if ENTRY_CONFIG.get(e.entry_type, {}).get("category") != 1:
            continue
        d = {}
        try:
            if e.details: d = json.loads(e.details)
        except Exception:
            pass
        pts = score_entry(e.entry_type, d)
        c1 += pts
        c1_breakdown[e.entry_type] = {
            "label": ENTRY_CONFIG[e.entry_type]["label"],
            "points": pts,
            "details": d,
        }

    # Mentor feedback (cat 1)
    if mentor_input:
        mf = mentor_input.mentor_feedback or ""
        mp = 15 if mf == "Excellent" else 10 if mf == "Good" else 5 if mf == "Average" else 0
        c1 += mp
        c1_breakdown["mentor_feedback"] = {
            "label": "Mentor Feedback", "points": mp}

        hf = mentor_input.hod_feedback or ""
        hp = 15 if hf == "Excellent" else 10 if hf == "Good" else 5 if hf == "Average" else 0
        c1 += hp
        c1_breakdown["hod_feedback"] = {
            "label": "HoD Feedback", "points": hp}

    cat1 = min(int(c1), 100)

    # ── Category 2: Student Development ──────────────────────────────────────
    c2 = 0
    c2_breakdown = {}

    # NPTEL — best one only
    nptel_entries = [e for e in entries if e.entry_type == "nptel"]
    if nptel_entries:
        best = max(nptel_entries, key=lambda e: e.score)
        c2 += best.score
        d = {}
        try:
            if best.details: d = json.loads(best.details)
        except Exception:
            pass
        c2_breakdown["nptel"] = {"label": "NPTEL/SWAYAM", "points": best.score, "details": d}

    # Online certs — count-based
    oc_entries = [e for e in entries if e.entry_type == "online_cert"]
    if oc_entries:
        cnt = len(oc_entries)
        oc_pts = 15 if cnt >= 3 else 10 if cnt == 2 else 5
        c2 += oc_pts
        c2_breakdown["online_cert"] = {
            "label": "Online Certifications", "count": cnt, "points": oc_pts}

    # Internship — best one only
    intern_entries = [e for e in entries if e.entry_type == "internship"]
    if intern_entries:
        best = max(intern_entries, key=lambda e: e.score)
        c2 += best.score
        d = {}
        try:
            if best.details: d = json.loads(best.details)
        except Exception:
            pass
        c2_breakdown["internship"] = {
            "label": "Internship", "points": best.score, "details": d}

    # Competition — best result
    comp_entries = [e for e in entries if e.entry_type == "competition"]
    if comp_entries:
        best = max(comp_entries, key=lambda e: e.score)
        c2 += best.score
        d = {}
        try:
            if best.details: d = json.loads(best.details)
        except Exception:
            pass
        c2_breakdown["competition"] = {
            "label": "Competition/Hackathon", "points": best.score, "details": d}

    # Publication
    pub_entries = [e for e in entries if e.entry_type == "publication"]
    if pub_entries:
        best = max(pub_entries, key=lambda e: e.score)
        c2 += best.score
        d = {}
        try:
            if best.details: d = json.loads(best.details)
        except Exception:
            pass
        c2_breakdown["publication"] = {
            "label": "Publication/Patent", "points": best.score, "details": d}

    # Skill programs — count-based
    sp_entries = [e for e in entries if e.entry_type == "skill_program"]
    if sp_entries:
        cnt = len(sp_entries)
        sp_pts = 15 if cnt >= 3 else 10 if cnt == 2 else 5
        c2 += sp_pts
        c2_breakdown["skill_program"] = {
            "label": "Skill Programs", "count": cnt, "points": sp_pts}

    cat2 = min(int(c2), 100)

    # ── Category 3: Skills & Readiness ───────────────────────────────────────
    c3 = 0
    c3_breakdown = {}

    # Mentor-evaluated (cat 3)
    if mentor_input:
        ts = mentor_input.tech_skill_level or ""
        tp = 20 if ts == "Excellent" else 10 if ts == "Good" else 5 if ts == "Basic" else 0
        c3 += tp
        c3_breakdown["tech_skill"] = {"label": "Technical Skill", "points": tp}

        ss = mentor_input.soft_skill_level or ""
        sp2 = 20 if ss == "Excellent" else 10 if ss == "Good" else 5 if ss == "Average" else 0
        c3 += sp2
        c3_breakdown["soft_skill"] = {"label": "Soft Skills", "points": sp2}

        po = mentor_input.placement_outcome or ""
        pp = (20 if po == "15+LPA" else 15 if po == "10-14LPA"
              else 10 if po == "7.5-9.9LPA" else 5 if po == "<7.5LPA" else 0)
        c3 += pp
        c3_breakdown["placement_outcome"] = {"label": "Placement Outcome", "points": pp}

    # Student-added (cat 3)
    for etype in ["placement_readiness", "innovation"]:
        e_list = [e for e in entries if e.entry_type == etype]
        if e_list:
            best = max(e_list, key=lambda e: e.score)
            c3 += best.score
            d = {}
            try:
                if best.details: d = json.loads(best.details)
            except Exception:
                pass
            c3_breakdown[etype] = {
                "label": ENTRY_CONFIG[etype]["label"],
                "points": best.score}

    # Industry interactions — count
    ii_entries = [e for e in entries if e.entry_type == "industry_interaction"]
    if ii_entries:
        cnt = len(ii_entries)
        ii_pts = 20 if cnt >= 3 else 10 if cnt == 2 else 5
        c3 += ii_pts
        c3_breakdown["industry_interaction"] = {
            "label": "Industry Interactions", "count": cnt, "points": ii_pts}

    # Research papers — count
    rp_entries = [e for e in entries if e.entry_type == "research_paper"]
    if rp_entries:
        cnt = len(rp_entries)
        rp_pts = 10 if cnt >= 3 else 5
        c3 += rp_pts
        c3_breakdown["research_paper"] = {
            "label": "Research Papers", "count": cnt, "points": rp_pts}

    cat3 = min(int(c3), 100)

    # ── Category 4: Discipline (fully mentor) ─────────────────────────────────
    c4 = 0
    c4_breakdown = {}

    if mentor_input:
        dc = mentor_input.discipline_conduct or ""
        dp = 20 if dc == "Exemplary" else 10 if dc == "Minor Issues" else 0
        c4 += dp
        c4_breakdown["discipline"] = {"label": "Discipline & Conduct", "points": dp}

        pl = mentor_input.punctuality_level or ""
        pp2 = 15 if pl == "ge95NoLate" else 10 if pl == "90-94" else 5 if pl == "85-89" else 0
        c4 += pp2
        c4_breakdown["punctuality"] = {"label": "Attendance & Punctuality", "points": pp2}

        dd = mentor_input.dress_code or ""
        dp2 = 15 if dd == "100% Adherence" else 10 if dd == "Highly Regular" else 5 if dd == "General" else 0
        c4 += dp2
        c4_breakdown["dress_code"] = {"label": "Dress Code", "points": dp2}

        de = mentor_input.dept_event_contribution or ""
        dep = 25 if de == "Impactful" else 15 if de == "Useful" else 5 if de == "Minor" else 0
        c4 += dep
        c4_breakdown["dept_events"] = {"label": "Dept Events Contribution", "points": dep}

        sm = mentor_input.social_media_level or ""
        smp = (25 if sm == "ActiveCreator" else 20 if sm == "Regular"
               else 15 if sm == "Shares" else 10 if sm == "Occasional"
               else 5 if sm == "Minimal" else 0)
        c4 += smp
        c4_breakdown["social_media"] = {"label": "Social Media", "points": smp}

    cat4 = min(int(c4), 100)

    # ── Category 5: Leadership ────────────────────────────────────────────────
    c5 = 0
    c5_breakdown = {}

    for etype in ["leadership_role", "team_management",
                  "innovation_initiative", "community_leadership"]:
        e_list = [e for e in entries if e.entry_type == etype]
        if e_list:
            best = max(e_list, key=lambda e: e.score)
            c5 += best.score
            c5_breakdown[etype] = {
                "label": ENTRY_CONFIG[etype]["label"], "points": best.score}

    # Event leadership — count events
    el_entries = [e for e in entries if e.entry_type == "event_leadership"]
    if el_entries:
        cnt = len(el_entries)
        el_pts = 15 if cnt >= 2 else 10
        c5 += el_pts
        c5_breakdown["event_leadership"] = {
            "label": "Event Leadership", "count": cnt, "points": el_pts}

    cat5 = min(int(c5), 100)

    # ── Total ─────────────────────────────────────────────────────────────────
    total = cat1 + cat2 + cat3 + cat4 + cat5

    stars = (5 if total >= 450 else 4 if total >= 400 else
             3 if total >= 350 else 2 if total >= 300 else
             1 if total >= 250 else 0)

    label = {5: "Excellent", 4: "Very Good", 3: "Good",
             2: "Average", 1: "Below Average", 0: "Not Rated Yet"}.get(stars, "")

    return {
        "total": total,
        "stars": stars,
        "label": label,
        "cat1": cat1, "cat2": cat2, "cat3": cat3, "cat4": cat4, "cat5": cat5,
        "breakdown": {
            "cat1": c1_breakdown,
            "cat2": c2_breakdown,
            "cat3": c3_breakdown,
            "cat4": c4_breakdown,
            "cat5": c5_breakdown,
        }
    }