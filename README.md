# LeadScrape Studio - Desktop Email Harvester

A Flutter Desktop application built for high-performance, automated lead generation and contractor email harvesting across US cities and states.

---

## 🚀 Key Features

1. **Automated Search Engine Harvesting**:
   - Executes search queries matching your exact pattern:
     `"[contractor] contractors in [city] [state] USA"`
   - Automatically parses search result links and discards Google internal apps (`google.com`, `maps`, `play`, `youtube`).
   - Filters aggregator/directory sites (Yelp, BBB, YellowPages) with toggleable settings.
2. **Multi-Stage Website Crawler**:
   - Visits contractor homepages and automatically scans for contact info (`mailto:` and regex pattern).
   - Auto-discovers and navigates to Contact / About pages if no email is found on the homepage.
3. **Facebook Page Email Scraping**:
   - Automatically detects Facebook business page URLs in the website's HTML.
   - Visits public Facebook page intro/about sections to extract official contact emails.
4. **Notepad & Direct Copy-Paste Workflow**:
   - **Notepad View**: Pure plaintext list of unique emails formatted line-by-line.
   - **One-Click "Copy All Emails"**: Instant clipboard copy ready for your email sender tool.
   - **Data Grid View**: Tabular view with contractor category, city, state, source, and clickable website & Facebook links.
5. **Contractor-by-Contractor Batch Saving**:
   - First contractor in the list is searched across all cities in the state $\rightarrow$ saved to:
     `outputs/[State]/[Contractor]_[State]_emails.txt` (and `.csv`)
   - Next contractor in the list across all cities in the state $\rightarrow$ saved to next file.
6. **Input Upload Support**:
   - Upload `contractors_list` from `.txt` or `.csv`.
   - Upload `cities_in_state` from `.json`, `.csv`, or `.txt`.
   - In-app chip editor to add/remove categories on the fly.

---

## 📁 Sample Inputs
Sample files are provided in the [`sample_inputs/`](file:///Users/ios_dev/StudioProjects/juniauto/sample_inputs) directory:
- [`contractors_list.txt`](file:///Users/ios_dev/StudioProjects/juniauto/sample_inputs/contractors_list.txt)
- [`cities_in_state.json`](file:///Users/ios_dev/StudioProjects/juniauto/sample_inputs/cities_in_state.json)
- [`cities_in_state.csv`](file:///Users/ios_dev/StudioProjects/juniauto/sample_inputs/cities_in_state.csv)

---

## 💻 How to Run

### macOS Desktop:
```bash
flutter run -d macos
```

### Windows Desktop:
```bash
flutter run -d windows
```

### Linux Desktop:
```bash
flutter run -d linux
```
