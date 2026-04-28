#!/usr/bin/env python3
"""
Gemini image generation script.
Usage: python3 generate-image.py "prompt" [draft|final] [aspect_ratio] [output_path]
"""

import os
import sys
from datetime import datetime
from pathlib import Path

VALID_RATIOS = {"1:1", "4:3", "3:4", "16:9", "9:16"}
MODELS = {
    "draft": "gemini-3.1-flash-image-preview",
    "final": "gemini-3-pro-image-preview",
}
DEFAULT_OUTPUT_DIR = Path.home() / "Documents" / "01 - Projects" / "Images"


def main():
    if len(sys.argv) < 2:
        print("Usage: generate-image.py \"prompt\" [draft|final] [aspect_ratio] [output_path]")
        sys.exit(1)

    prompt = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "draft"
    aspect_ratio = sys.argv[3] if len(sys.argv) > 3 else "16:9"
    output_path = sys.argv[4] if len(sys.argv) > 4 else None

    if mode not in MODELS:
        print(f"Invalid mode '{mode}'. Use: draft or final")
        sys.exit(1)

    if aspect_ratio not in VALID_RATIOS:
        print(f"Invalid aspect ratio '{aspect_ratio}'. Valid: {', '.join(sorted(VALID_RATIOS))}")
        sys.exit(1)

    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("GOOGLE_API_KEY not set. Run: gemini login or export GOOGLE_API_KEY=...")
        sys.exit(1)

    try:
        from google import genai
        from google.genai import types
    except ImportError:
        print("google-genai not installed. Run: pip3 install -U google-genai")
        sys.exit(1)

    model_id = MODELS[mode]
    client = genai.Client(api_key=api_key)

    print(f"Generating image: model={model_id}, ratio={aspect_ratio}, mode={mode}")

    response = client.models.generate_content(
        model=model_id,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_modalities=["IMAGE"],
            image_config=types.ImageConfig(aspect_ratio=aspect_ratio),
        ),
    )

    image_part = next(
        (p for p in response.candidates[0].content.parts if p.inline_data),
        None,
    )

    if not image_part:
        print("No image returned. Check prompt or try again.")
        sys.exit(1)

    if output_path:
        save_path = Path(output_path)
    else:
        DEFAULT_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        save_path = DEFAULT_OUTPUT_DIR / f"gemini-{mode}-{timestamp}.png"

    save_path.parent.mkdir(parents=True, exist_ok=True)
    with open(save_path, "wb") as f:
        f.write(image_part.inline_data.data)

    print(f"Saved: {save_path}")


if __name__ == "__main__":
    main()
