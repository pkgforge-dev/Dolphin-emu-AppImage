---
name: "Bug report - AppImage (please attach debug log)"
about: "Report crashes or other bugs. Run the AppImage with APPIMAGE_DEBUG=1 and attach the generated log file."
---

Please fill out the sections below.

## Collect the AppImage debug log (required)
1. Run the AppImage with debug enabled:
   ```sh
   APPIMAGE_DEBUG=1 ./MyApp.AppImage
   ```
   - The AppImage will create a debug log automatically and will print the path to that log file in the terminal output.
   - Attach that file to this issue.

## Make sure to ping the maintainer of the repository when making the bug report
- Often times we miss emails because not all repositories are watched automatically after being made, so please ping the maintainer of the repository when making the issue. Simply add @name-of-maintainer.

## Checklist
- [ ] I ran the AppImage with `APPIMAGE_DEBUG=1` environment variable set.
- [ ] I attached the debug log produced by the AppImage.
- [ ] I pinged the maintainer of the repository.

