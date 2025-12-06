# Project Showcase Poster - User Guide

## Overview
A professional A1-sized poster has been created for your AI-Enabled Digital Health Platform project showcase. The poster is designed to be accessible to both technical and non-technical audiences.

## File Location
- **Poster File**: `Documents/showcase_poster.html`

## How to View the Poster

### Method 1: Open in Browser
1. Navigate to the `Documents` folder
2. Double-click `showcase_poster.html` or right-click and select "Open with" → your web browser
3. The poster will display in A1 portrait format (594mm × 841mm)

### Method 2: Live Preview (VS Code)
If you're using VS Code:
1. Install the "Live Server" extension
2. Right-click on `showcase_poster.html`
3. Select "Open with Live Server"

## How to Export to PDF for Printing

### Option 1: Using Chrome/Edge (Recommended)
1. Open `showcase_poster.html` in Chrome or Edge
2. Press `Ctrl+P` (Windows/Linux) or `Cmd+P` (Mac)
3. In the print dialog:
   - **Destination**: Select "Save as PDF"
   - **Paper size**: Select "A1" (if available) or "Custom" → 594mm × 841mm
   - **Margins**: Select "None"
   - **Scale**: 100%
   - **Background graphics**: ✓ Enabled
4. Click "Save" and choose your location

### Option 2: Using Firefox
1. Open `showcase_poster.html` in Firefox
2. Press `Ctrl+P` (Windows/Linux) or `Cmd+P` (Mac)
3. Configure:
   - **Paper size**: Custom → 594mm × 841mm
   - **Margins**: None
   - **Print backgrounds**: ✓ Enabled
4. Click "Save to PDF"

### Option 3: Professional Printing Service
For the best quality:
1. Export to PDF using the methods above
2. Send the PDF to a professional printing service
3. Request: **A1 size (594mm × 841mm), portrait orientation, high-quality color print**

## Customization Guide

### Changing Colors
The poster uses a blue color scheme. To change colors, edit these CSS variables in the `<style>` section:

```css
/* Primary blue gradient */
background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);

/* Accent colors */
color: #1e3a8a;  /* Dark blue for headings */
border-left: 5px solid #3b82f6;  /* Light blue accent */
```

### Modifying Text Content
Simply find the relevant section in the HTML and edit the text directly. The structure is organized as:
- `.header` - Title and metadata
- `.section` - Each content section (Introduction, Problem, etc.)

### Adjusting Spacing
To modify spacing between sections:
```css
.content {
    gap: 20mm;  /* Adjust this value */
}
```

### Adding Your Logo
To add a university or client logo:
1. Save your logo image to the `Documents` folder
2. Add this code in the `.header` section:
```html
<img src="your-logo.png" style="height: 30mm; margin-bottom: 10mm;" alt="Logo">
```

## Design Features

### For Mixed Audience
- **Visual Hierarchy**: Clear section headings with icons
- **Highlight Boxes**: Key information emphasized in colored boxes
- **Simple Language**: Technical terms explained in context
- **Visual Elements**: Pain points grid, technology stack cards, architecture diagram

### Professional Elements
- **Color Scheme**: Professional blue gradient (trust, healthcare)
- **Typography**: Inter (body) + Roboto Slab (headings) for readability
- **Layout**: Two-column grid for optimal information density
- **White Space**: Adequate spacing for easy scanning

## Poster Structure
1. **Header** - Project title, subtitle, and metadata
2. **Introduction** - Project overview and vision
3. **Problem** - Problem statement with patient/clinician pain points
4. **Literature Review** - Market gap analysis
5. **Methodology** - System architecture, tech stack, AI core
6. **Conclusion** - Project impact and validation
7. **Future Works** - Next steps and recommendations
8. **References** - Citations in standard format

## Tips for Showcase Presentation

### Before Printing
- ✓ Proofread all text content
- ✓ Check that all references are correct
- ✓ Verify contact information
- ✓ Add team member names if required
- ✓ Print a test page (A4) to check colors

### During Showcase
- Stand beside the poster to answer questions
- Prepare a 2-minute elevator pitch
- Have business cards or contact info ready
- Consider preparing a demo on a tablet/laptop to complement the poster

### For Technical Audience
Emphasize:
- System architecture and microservices design
- LangChain framework and autonomous agent capabilities
- Technology choices (Flutter, FastAPI, Supabase)
- Row-Level Security implementation

### For Non-Technical Audience
Focus on:
- Patient empowerment and improved health outcomes
- Solving real-world healthcare challenges in Malaysia
- Proactive vs. reactive care transformation
- "Attention funnel" for clinicians (prioritising high-risk patients)

## Troubleshooting

### Poster doesn't display correctly in browser
- Ensure you're using a modern browser (Chrome, Firefox, Edge, Safari)
- Try zooming out (Ctrl + Mouse wheel or Cmd + Mouse wheel)
- Check browser zoom is set to 100%

### Colors look different when printed
- Enable "Print background graphics" in print settings
- Use a professional printing service for color accuracy
- Request a color proof before final print

### Text is too small/large
Adjust the base font sizes in CSS:
```css
.section p {
    font-size: 14pt;  /* Increase or decrease */
}
```

## Need Help?
If you need to make specific customizations or encounter issues:
1. Check this guide first
2. Try searching for CSS/HTML tutorials for specific changes
3. Ask for assistance from team members with web development experience

---

**Created for**: BioTective Sdn Bhd Project
**Unit**: COS40005 - Computing Technology Project A
**Format**: A1 Portrait (594mm × 841mm)
**File Type**: HTML/CSS (print-ready)
