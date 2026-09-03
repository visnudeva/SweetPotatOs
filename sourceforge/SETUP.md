SourceForge project setup checklist
====================================

1) Upload ISO only (needs your SF password or SSH key):
   SF_USER=YOUR_SF_USERNAME ./sourceforge/upload.sh

   Overlay packages for spo-upgrade go to GitHub, not SourceForge Files:
   ./github/upload-repo.sh

2) Mirror GitHub → SourceForge Git (one-time, then push when releasing):
   # Add ~/.ssh/id_ed25519_sourceforge.pub under
   #   https://sourceforge.net/auth/shell_services  (Account Services → SSH keys)
   git remote add sourceforge ssh://visnudeva@git.code.sf.net/p/sweetpotatos/code
   git push -u sourceforge main

3) In https://sourceforge.net/projects/sweetpotatos/ — Admin → Settings:
   - Icon: upload assets/SweetPotatOs.png or assets/SPLogo.png
   - Summary: paste sourceforge/PROJECT_SUMMARY.txt
   - Categories: e.g. System, Linux, Desktop Environment
   - External homepage: https://github.com/visnudeva/SweetPotatOs
   - Mirror preferred download name if asked

4) After upload, set default download:
   Files → (release folder) → (i) on the .iso → select as default download

5) Project web (uploaded by the script) appears at:
   https://sweetpotatos.sourceforge.io/
