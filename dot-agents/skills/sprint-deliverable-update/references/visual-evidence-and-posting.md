# Visual Evidence and Posting

Use this reference when a deliverable comment includes screenshots or generated evidence images.

## Readiness definitions

- **Review-ready:** the Markdown contains actual image embeds. Relative paths are allowed only inside a bundle whose image files exist beside the Markdown.
- **Post-ready:** every image embed uses a live HTTPS URL. No local paths, upload instructions, or editorial placeholders remain.
- **Posted and verified:** the created GitHub comment's rendered HTML contains the same number of `<img>` elements as the Markdown contains image embeds.

## Authorization boundary

Authorization to post a public issue comment does not authorize installing an extension, reading an authenticated browser session, creating a public gist, or changing global Git credentials. Get separate explicit approval for whichever upload path is needed. Never run `gh auth setup-git` in this workflow; scope any Git credential helper to the single push command.

## Preferred upload: GitHub user attachments

GitHub user attachments produce `https://github.com/user-attachments/assets/<uuid>` URLs and are the preferred destination.

```bash
# Require the reviewed version. Stop and ask if it is missing or different.
gh extension list | grep -q 'sudosubin/gh-attach.*v0.3.2'
```

Only after separate approval to install or replace it:

```bash
gh extension install sudosubin/gh-attach --pin v0.3.2 --force
```

Only after separate approval to access the browser session:

```bash
gh attach ./image.png \
  -R OWNER/REPO \
  --browser auto \
  --json href,name
```

`gh attach` needs an authenticated GitHub browser session in addition to `gh` API authentication. Diagnose one failure with `--verbose`. If every source reports missing cookies or `dotcom_user`, stop retrying that method; `gh auth status` alone cannot satisfy the web attachment flow.

Never print browser cookies, upload policies, CSRF tokens, S3 form data, or GitHub tokens.

## GitHub-hosted fallback

Use this only when all of the following are true:

- the user authorized the public GitHub post;
- the user separately authorized creating the unlisted public gist;
- the images are intentionally public evidence;
- native user-attachment upload is unavailable after one diagnosed attempt;
- the user has not required `user-attachments` specifically.

Create one **secret (unlisted, not private)** gist, push the binary PNGs to it, and use versioned `gist.githubusercontent.com` raw URLs. Once linked from a public issue, those URLs are public.

```bash
printf '%s\n' 'Image assets for a GitHub deliverable summary.' > /tmp/gist-readme.md
gist_url=$(gh gist create /tmp/gist-readme.md -d 'Deliverable summary screenshots')
gist_id=${gist_url##*/}

gh gist clone "$gist_id" /tmp/deliverable-images
cp /path/to/*.png /tmp/deliverable-images/
git -C /tmp/deliverable-images add '*.png'
git -C /tmp/deliverable-images commit -m 'Add deliverable screenshots'
git -C /tmp/deliverable-images \
  -c credential.helper= \
  -c 'credential.helper=!gh auth git-credential' \
  push origin HEAD

gh api "gists/$gist_id" \
  --jq '.files | to_entries[] | [.key,.value.raw_url,.value.type,.value.size] | @tsv'
```

Do not use release assets or non-GitHub image hosts for deliverable evidence.

## Validate before posting

```bash
SPRINT_DELIVERABLE_SKILL_DIR=/absolute/path/to/sprint-deliverable-update
ARTIFACT=deliverable-summary  # or sprint-update
validation_output=$(python3 "$SPRINT_DELIVERABLE_SKILL_DIR/scripts/validate-deliverable-comment.py" \
  --artifact "$ARTIFACT" \
  --mode post \
  --check-urls \
  /tmp/deliverable-comment.md)
printf '%s\n' "$validation_output"
expected_images=$(printf '%s\n' "$validation_output" | sed -E 's/.*: ([0-9]+) image\(s\)/\1/')
```

The validator must report zero placeholders and confirm every image URL returns an image content type.

## Post and verify rendering

```bash
comment_url=$(gh issue comment ISSUE \
  --repo OWNER/REPO \
  --body-file /tmp/deliverable-comment.md)
comment_id=${comment_url##*-}

rendered_images=$(gh api \
  -H 'Accept: application/vnd.github.full+json' \
  "repos/OWNER/REPO/issues/comments/$comment_id" \
  --jq '[.body_html | scan("<img(?:\\s|>)")] | length')
test "$rendered_images" -eq "$expected_images"
printf '%s\n' "$comment_url"
```

The rendered image count must match the validator's Markdown image count. Report the exact comment URL only after this check passes.
