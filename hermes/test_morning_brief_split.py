from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MANIFEST = ROOT / "manifest.json"
WORK_PROMPT = ROOT / "automations" / "workday-morning-brief" / "prompt.md"
PERSONAL_PROMPT = ROOT / "automations" / "personal-morning-brief" / "prompt.md"
WORK_COLLECTOR = ROOT / "scripts" / "sgg-morning-brief.py"
WORK_SYNC = ROOT / "scripts" / "sgg-sync-workday-note.py"
PERSONAL_COLLECTOR = ROOT / "scripts" / "personal-morning-brief.py"
ALIGNMENT_COLLECTOR = ROOT / "scripts" / "personal-alignment-brief.py"


class MorningBriefSplitContractTest(unittest.TestCase):
    def test_manifest_pins_each_agent_job_to_its_intended_model(self) -> None:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        jobs = {job["name"]: job for job in manifest["cronJobs"]}
        expected = {
            "Workday Morning Brief": ("gpt-5.6-terra", "openai-codex", None),
            "Personal Morning Brief": ("gemma4:31b-mlx", "custom", "http://127.0.0.1:11434/v1"),
            "Personal Weekday Close": ("gemma4:31b-mlx", "custom", "http://127.0.0.1:11434/v1"),
            "Personal Saturday Orientation": ("gemma4:31b-mlx", "custom", "http://127.0.0.1:11434/v1"),
            "Personal Sunday Reset": ("gemma4:31b-mlx", "custom", "http://127.0.0.1:11434/v1"),
            "Workday Dependency Triage": ("gpt-5.6-sol", "openai-codex", None),
        }

        self.assertEqual(set(jobs), set(expected))
        for name, (model, provider, base_url) in expected.items():
            self.assertEqual(jobs[name]["model"], model)
            self.assertEqual(jobs[name]["provider"], provider)
            self.assertEqual(jobs[name].get("baseUrl"), base_url)

    def test_manifest_routes_personal_morning_brief_to_second_brain(self) -> None:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        job = next(job for job in manifest["cronJobs"] if job["name"] == "Personal Morning Brief")

        self.assertEqual(job["schedule"], "20 7 * * 1-5")
        self.assertEqual(job["model"], "gemma4:31b-mlx")
        self.assertEqual(job["provider"], "custom")
        self.assertEqual(job["baseUrl"], "http://127.0.0.1:11434/v1")
        self.assertEqual(job["deliver"], "matrix:!5hH-Wud0Gd7hS1Z214EwjEMUvqtH8FBVOZhIZj0sqR4")
        self.assertEqual(job["script"], "personal-morning-brief.py")
        self.assertEqual(job["workdir"], "/Users/bryan/second-brain")
        self.assertTrue(job["attachToSession"])
        self.assertEqual(job["continuation"]["chatName"], "Second Brain")

    def test_work_brief_excludes_personal_sources_and_sections(self) -> None:
        prompt = WORK_PROMPT.read_text(encoding="utf-8")
        collector = WORK_COLLECTOR.read_text(encoding="utf-8")

        self.assertIn("Personal projects, personal reminders, and personal calendar events belong in the Second Brain morning brief", prompt)
        self.assertNotIn("**Other recent projects**", prompt)
        self.assertNotIn("**Today's reminders**", prompt)
        self.assertNotIn("SECOND_BRAIN", collector)
        self.assertNotIn("collect_reminders", collector)
        self.assertIn('WORK_CALENDARS = {"Bryan @ Agile6"}', collector)

    def test_work_brief_uses_project_owned_sgg_vault(self) -> None:
        prompt = WORK_PROMPT.read_text(encoding="utf-8")
        collector = WORK_COLLECTOR.read_text(encoding="utf-8")
        sync_helper = WORK_SYNC.read_text(encoding="utf-8")

        self.assertIn("/Users/bryan/code/sgg/vault/AGENTS.md", prompt)
        self.assertIn("/Users/bryan/code/sgg/vault/workdays/DAY.md", prompt)
        self.assertNotIn("/Users/bryan/code/notes/sgg", prompt)
        self.assertIn('VAULT_ROOT = SGG_ROOT / "vault"', collector)
        self.assertIn('git_history(SGG_ROOT, since, "vault")', collector)
        self.assertNotIn("NOTES_ROOT", collector)
        self.assertIn('WORKSPACE_ROOT / "vault" / "workdays"', sync_helper)
        self.assertIn('relative = f"vault/workdays/{day}.md"', sync_helper)
        self.assertNotIn('Path.home() / "code" / "notes"', sync_helper)

    def test_personal_brief_excludes_sgg_work_details(self) -> None:
        prompt = PERSONAL_PROMPT.read_text(encoding="utf-8")
        collector = PERSONAL_COLLECTOR.read_text(encoding="utf-8")

        self.assertIn("Detailed SGG work state belongs only in the SGG morning brief", prompt)
        self.assertNotIn("SGG_NOTES", collector)
        self.assertIn('EXCLUDED_CALENDARS = {"Bryan @ Agile6", "Traci"}', collector)
        self.assertIn("Never use or mention events from Traci's calendar", prompt)
        self.assertIn("recentSecondBrainPaths", collector)

    def test_personal_routines_do_not_resurface_alcohol_by_default(self) -> None:
        prompt_paths = [
            PERSONAL_PROMPT,
            ROOT / "automations" / "personal-weekday-close" / "prompt.md",
            ROOT / "automations" / "personal-saturday-orientation" / "prompt.md",
            ROOT / "automations" / "personal-sunday-reset" / "prompt.md",
        ]
        for path in prompt_paths:
            prompt = path.read_text(encoding="utf-8").lower()
            self.assertIn("never", prompt, path)
            self.assertIn("sobriety", prompt, path)
            if path != PERSONAL_PROMPT:
                self.assertIn("unless bryan explicitly raises", prompt, path)

        skill = (ROOT / "skills" / "productivity" / "personal-routine-automation" / "SKILL.md").read_text(encoding="utf-8")
        contract = (ROOT / "skills" / "productivity" / "personal-routine-automation" / "references" / "bryan-personal-routine-contract.md").read_text(encoding="utf-8")
        self.assertNotIn("Bryan's alcohol direction is near-abstinence", skill)
        self.assertNotIn("Alcohol direction: as close to abstinence", contract)
        self.assertIn("unless Bryan explicitly raises that topic in the current conversation", skill)
        self.assertIn("unless Bryan explicitly raises that topic in the current conversation", contract)

    def test_personal_weather_uses_private_configuration(self) -> None:
        for path in (PERSONAL_COLLECTOR, ALIGNMENT_COLLECTOR):
            collector = path.read_text(encoding="utf-8")

            self.assertIn('os.environ.get("PERSONAL_WEATHER_LOCATION", "")', collector)
            self.assertIn('HOME / ".secrets" / "personal-weather-location"', collector)
            self.assertIn('f"https://wttr.in/{quote(location)}?format=j1"', collector)
            self.assertNotIn("wttr.in IP geolocation", collector)

    def test_work_brief_does_not_promote_proposals_or_other_peoples_actions(self) -> None:
        prompt = WORK_PROMPT.read_text(encoding="utf-8")

        self.assertIn(
            "A proposal, deadline, meeting discussion, or action assigned to someone else is not Bryan's priority",
            prompt,
        )
        self.assertIn("Prefer an explicit current resting point", prompt)
        self.assertIn("Preserve assignees exactly", prompt)
        self.assertIn(
            "If no source explicitly establishes Bryan's primary outcome, say so rather than inventing one",
            prompt,
        )


if __name__ == "__main__":
    unittest.main()
