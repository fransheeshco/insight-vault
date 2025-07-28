import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { BlobServiceClient } from "@azure/storage-blob";
import * as dotenv from 'dotenv'

dotenv.config()

export async function uploadCSV(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    try {
        const fileBuffer = await request.arrayBuffer();
        const filename = request.query.get("filename") || request.headers.get("x-filename");

        if (!filename || !fileBuffer) {
            return {
                status: 400,
                body: "Missing file or filename. Please include a file and filename query/header."
            }
        }
        const blobServiceClient = BlobServiceClient.fromConnectionString(
            process.env.AZURE_STORAGE_CONNECTION_STRING!
        )

        const containerName = "csv-uploads";
        const containerClient = blobServiceClient.getContainerClient(containerName);
        await containerClient.createIfNotExists();

        context.log(`Uploading file: ${filename}`);
        context.log(`File buffer size: ${fileBuffer.byteLength}`);

        const blockBlobClient = containerClient.getBlockBlobClient(filename);
        await blockBlobClient.uploadData(Buffer.from(fileBuffer), {
            blobHTTPHeaders: { blobContentType: "text/csv" }
        });

        return {
            status: 200,
            body: `Successfully uploaded "${filename}" to blob storage.`
        };

    } catch (error) {
        context.error("Upload failed", error);
        return {
            status: 500,
            body: "Something went wrong during the file upload."
        };
    }
};

app.http('uploadCSV', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: uploadCSV
});
