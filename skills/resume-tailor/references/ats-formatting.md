# ATS formatting

Most large companies and many medium ones parse résumés through an Applicant Tracking System before a human reads them. If the parser can't read your résumé, a human never sees it.

## File format

### PDF: yes, usually

- PDFs render consistently across devices.
- Modern ATS parsers (Workday, Greenhouse, Lever, iCIMS) read PDFs well.
- Only produce PDFs from Word / Google Docs / Pages — not from screenshots.

### Word (.docx): safer for older systems

- Some legacy ATS only reliably parse Word.
- If the application says "upload résumé", PDF. If it says "please submit in Word or RTF", Word.

### Never

- PNG / JPG / screenshot.
- PDF-from-scan (image-based, not text).
- Pages (.pages) — convert to PDF or Word.

## Layout

### Single column, top-to-bottom

Multi-column layouts look great to a human; many parsers stumble through them:

```
❌ Two-column layout: skills on left, experience on right.
✅ Single column: header → experience → skills → education.
```

### No tables

Tables confuse parsers. Everything that looks like a table should be bullets or plain text:

```
❌ A table with columns "Role", "Company", "Dates".
✅ Role — Company (Dates) as a header line, followed by bullets.
```

### Simple fonts

- Arial, Calibri, Georgia, Times New Roman, Helvetica.
- 10–12pt body, 14–16pt headers.
- Don't use fantasy fonts, serifs with low x-height, or decorative typography.

### No text in images, charts, or icons

If the ATS can't copy-paste it as text, it doesn't exist. Logos, skill-bar charts, "rating" bubbles — all invisible to the parser.

### No text boxes

Modern parsers handle them better than they used to, but still unreliable in legacy systems.

### Headers and footers — use cautiously

Contact info in a header sometimes gets skipped. Safest: put name + contact at the top of the body.

## Section headers

Use the obvious names — parsers look for them:

- **Experience** / **Work Experience** / **Professional Experience**
- **Education**
- **Skills**
- **Projects**
- **Publications**
- **Certifications**

Avoid cute headers like "Where I've Worked" or "My Toolkit". The parser won't recognize them as sections.

## The structure — single page, reverse-chronological

```
# Your Name
email@example.com · (555) 555-5555 · linkedin.com/in/you · github.com/you · yourcity, country

## Experience

### Senior Software Engineer — Company A (Jan 2023 – Present)
- Bullet 1.
- Bullet 2.
- Bullet 3.

### Software Engineer — Company B (Jun 2020 – Dec 2022)
- Bullet 1.
- Bullet 2.

## Education

### B.S. Computer Science — University X (2020)

## Skills

Languages: Go, TypeScript, Python
Frameworks: Angular, NgRx, Node.js
Tools: AWS, Postgres, Kubernetes, Docker
```

- **Name big** (20–24pt) at the top.
- **Contact line** horizontal, one line.
- **Role on the left, dates on the right** — makes scanning easy (date-first scanning).
- **Company as secondary** — smaller than role, same line.
- **Bullets in consistent format** — start with strong verb, end with result.

## Dates — standardize

```
✅ Jan 2023 – Present
✅ 2020 – 2022
✅ Jun 2020 – Dec 2022

❌ 1/2023 – Now
❌ January '23 – Present
```

Gaps are less of a problem than they were; don't obfuscate. If you have a gap, explain it briefly in the cover letter if relevant, otherwise don't call attention to it.

## Skills section

- Group: **Languages / Frameworks / Tools / Databases**.
- Comma-separated, no bars, no skill-level graphics.
- Put the most relevant to the JD first.
- Don't list "Microsoft Office" or "Email".

## Keywords

ATS scans for keywords from the JD. In the skills + experience sections, use the JD's terminology where it's also true of you.

Don't keyword-stuff white-on-white at the bottom. Modern parsers flag this. Old trick, doesn't work anymore.

## File naming

```
✅ Firstname-Lastname-Resume.pdf
✅ Firstname-Lastname-Resume-CompanyName.pdf
❌ Resume.pdf
❌ NEW_RESUME_FINAL_v3_actually-final.pdf
```

Makes recruiter filing easy. Slightly more likely to be remembered.

## Testing your résumé

Two cheap tests:

1. **Copy-paste test**: open your PDF, select all, paste into a plain-text editor. Does the output read coherently, in the order you intended? If not, the ATS will parse it out of order.
2. **ATS preview**: upload to [Jobscan](https://www.jobscan.co) or [Resume Worded](https://resumeworded.com/) — free tier gives you a rough ATS score against a specific JD.

Fix anything that reads garbled.

## Things that still matter to humans

Even with ATS optimization, a human reads the résumé once it passes the parser. For humans:

- Visual hierarchy — the eye should flow top-to-bottom, left-to-right.
- Whitespace — cramped résumés get skimmed faster.
- Consistency — every bullet follows the same format.
- One page (unless senior / 10+ years). Two pages max.

Don't sacrifice human readability for ATS tricks. Aim for both.
