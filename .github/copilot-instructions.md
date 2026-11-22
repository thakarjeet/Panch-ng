# Panchang project instructions

- Keep all Panchang and astronomy calculations on-device in pure Dart. Runtime code must not call a web service or require network access.
- Use explicit algorithms and cite/reference the source of astronomical constants and comparison fixtures. Never invent almanac values.
- Keep calculation code independent of Flutter widgets and add focused tests for numerical and calendrical behavior.
- Explain uncertainty and tradition-specific choices; muhurat results are traditional guidelines, not guarantees.
- Preserve offline operation, zero-cost dependencies, and Gujarati, Hindi, and English support.
- Build Android APKs in GitHub Actions and publish them as downloadable workflow artifacts; do not require paid services or signing secrets.
