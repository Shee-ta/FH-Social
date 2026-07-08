package com.fhsocial.backend.Services;

import java.util.ArrayList;
import java.util.List;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.cos.COSName;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.graphics.PDXObject;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;
import org.apache.pdfbox.text.PDFTextStripper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.fhsocial.backend.DTO.FileChunkDTO;
import com.fhsocial.backend.DTO.ProcessedFileDTO;
import com.fhsocial.backend.DTO.ProcessedImageDTO;
import net.sourceforge.tess4j.Tesseract;

@Service
public class FileProcessorService {

    private Logger logger = LoggerFactory.getLogger(FileProcessorService.class);

    private String getExtension(String name) {
        if (name == null || name.isBlank()) {
            return "";
        }
        int dotIndex = name.lastIndexOf(".");
        if (dotIndex >= 0) {
            return name.substring(dotIndex + 1);
        }
        return "";
    }

    private ProcessedFileDTO processPDF(MultipartFile file) {

        try (PDDocument document = Loader.loadPDF(file.getBytes())) {

            List<ProcessedImageDTO> images = new ArrayList<>();
            List<FileChunkDTO> chunks = new ArrayList<>();

            Tesseract tesseract = new Tesseract();
            tesseract.setDatapath(System.getenv("TESSDATA_PREFIX"));
            tesseract.setLanguage("eng+deu");

            PDFTextStripper stripper = new PDFTextStripper();

            int imageCounter = 1;

            for (int i = 0; i < document.getNumberOfPages(); i++) {

                StringBuilder markdown = new StringBuilder();

                int pageNumber = i + 1;

                markdown.append("## Page " + pageNumber + "\n\n");

                stripper.setStartPage(pageNumber);
                stripper.setEndPage(pageNumber);

                String pageText = stripper.getText(document).trim();

                if (!pageText.isBlank()) {
                    markdown.append(pageText).append("\n\n");
                }

                PDPage page = document.getPage(i);

                for (COSName name : page.getResources().getXObjectNames()) {

                    PDXObject object = page.getResources().getXObject(name);

                    if (object instanceof PDImageXObject image) {

                        // BufferedImage buffered = image.getImage();

                        // ByteArrayOutputStream baos = new ByteArrayOutputStream();

                        // ImageIO.write(buffered, "png", baos);

                        // byte[] imageBytes = baos.toByteArray();

                        // String base64 = Base64.getEncoder().encodeToString(imageBytes);

                        // String ocrText = "";

                        // File temp = File.createTempFile("ocr", ".png");

                        // try {
                        //     ImageIO.write(buffered, "png", temp);

                        //     ocrText = tesseract.doOCR(temp);

                        //     temp.delete();
                        // }
                        // catch (Exception ignored) {

                        // }
                        // finally {
                        //     Files.deleteIfExists(temp.toPath());
                        // }

                        // markdown.append(
                        //         "### Image ")
                        //         .append(imageCounter)
                        //         .append("\n\n");

                        // if (!ocrText.isBlank()) {
                        //     markdown.append(
                        //         "OCR text:\n")
                        //         .append(ocrText)
                        //         .append("\n\n");
                        // }
                        // else {
                        //     markdown.append("[No OCR text detected]\n\n");
                        // }

                        // images.add(new ProcessedImageDTO(
                        //         imageCounter,
                        //         Integer.toString(pageNumber),
                        //         ocrText,
                        //         base64
                        //     )
                        // );

                        // imageCounter++;
                    }
                }

                chunks.add(new FileChunkDTO(
                    pageNumber,
                    "Page " + pageNumber,
                    "Page " + pageNumber,
                    markdown.toString()
                    )
                );
            }

            return new ProcessedFileDTO(
                    chunks,
                    images
            );
        }
        catch (Exception e) {
            logger.error("Failed to process file {} with error {}", file.getOriginalFilename(), e.getMessage());
            return null;
        }
    }

    public ProcessedFileDTO process(MultipartFile file) throws Exception {

        switch (getExtension(file.getOriginalFilename())) {
            case "pdf":
                return processPDF(file);
            default:
                return null;
        }
    }
}
