import os
from fpdf import FPDF
from datetime import datetime

SAMPLE_PDF_DIR = 'reports/sample_pdfs'
os.makedirs(SAMPLE_PDF_DIR, exist_ok=True)

def generate_sample_pdf(filename: str, title: str, findings: str, recommendations: str, status: str):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font('Arial', 'B', 16)
    pdf.cell(0, 10, f'Report Title: {title}', ln=True)
    pdf.set_font('Arial', '', 12)
    pdf.cell(0, 10, f'Status: {status}', ln=True)
    pdf.cell(0, 10, f'Date: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}', ln=True)
    pdf.ln(10)
    pdf.set_font('Arial', 'B', 12)
    pdf.cell(0, 10, 'Findings:', ln=True)
    pdf.set_font('Arial', '', 12)
    pdf.multi_cell(0, 10, findings)
    pdf.ln(5)
    pdf.set_font('Arial', 'B', 12)
    pdf.cell(0, 10, 'Recommendations:', ln=True)
    pdf.set_font('Arial', '', 12)
    pdf.multi_cell(0, 10, recommendations)
    pdf.output(os.path.join(SAMPLE_PDF_DIR, filename))
    return os.path.join(SAMPLE_PDF_DIR, filename)

if __name__ == '__main__':
    # Example usage for all statuses
    statuses = ['scheduled', 'pending_review', 'completed', 'rejected']
    for status in statuses:
        generate_sample_pdf(
            filename=f'sample_{status}.pdf',
            title=f'Sample Report ({status.title()})',
            findings=f'This is a sample findings section for status: {status}.',
            recommendations=f'This is a sample recommendations section for status: {status}.',
            status=status.title()
        )
    print('Sample PDFs generated in', SAMPLE_PDF_DIR)
