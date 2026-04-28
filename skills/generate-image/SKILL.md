---
name: generate-image
description: Generates images using Google Nano Banana (Gemini image models). Two modes: draft (Nano Banana 2 / fast) and final (Nano Banana Pro / high quality). Saves PNG to ~/Documents/01 - Projects/Images/.
---

# Generate Image Skill

Calls the Gemini image generation API via a Python script. Requires `GOOGLE_API_KEY` to be set.

## Invocation

`/generate-image "prompt" [draft|final] [aspect_ratio] [output_path]`

- `draft` (default): Nano Banana 2 (gemini-3.1-flash-image-preview). Fast, for iteration and mockups.
- `final`: Nano Banana Pro (gemini-3-pro-image-preview). High-fidelity, for production assets.
- `aspect_ratio`: one of `1:1`, `4:3`, `3:4`, `16:9` (default), `9:16`
- `output_path`: optional. Defaults to `~/Documents/01 - Projects/Images/gemini-{mode}-{timestamp}.png`

## Protocol

1. Confirm the prompt, mode, and aspect ratio with the user before generating if any is ambiguous.
2. Run the script:

   ```bash
   python3 ~/.claude/scripts/generate-image.py \
     "PROMPT" \
     draft \
     "16:9"
   ```

3. Read the output line starting with `Saved:` to get the file path.
4. Report the saved path to the user. Do not display the image inline unless explicitly asked.
5. If the script returns an error, surface it verbatim and stop.

## Mode guidance

- Use `draft` for: blog post mockups, layout tests, concept generation, anything you will iterate on.
- Use `final` for: production blog hero images, any image that will be published.

## Notes

- All generated images include a SynthID invisible watermark (Google standard).
- Do not pass credentials, private data, or personally identifiable information in prompts.
- If `GOOGLE_API_KEY` is missing, tell the user to check `~/.zshrc` or `~/.bashrc`, or restart their Claude Code session.
