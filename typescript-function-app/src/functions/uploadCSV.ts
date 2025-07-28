import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { BlobServiceClient } from "@azure/storage-blob";
import * as dotenv from "dotenv";

dotenv.config();

export async function uploadCSV(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  try {
    const fileBuffer = await request.arrayBuffer();
    const filename = request.query.get("filename") || request.headers.get("x-filename");

    if (!filename || !fileBuffer) {
      return {
        status: 400,
        body: "Missing file or filename. Please include a file and filename query/header.",
      };
    }

    const connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
    if (!connectionString) {
      return {
        status: 500,
        body: "Storage connection string not found in environment variables.",
      };
    }

    const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
    const containerName = "csv-uploads";
    const containerClient = blobServiceClient.getContainerClient(containerName);

    // ✅ Create container if it doesn't exist
    const createContainerResponse = await containerClient.createIfNotExists();
    if (createContainerResponse.succeeded) {
      context.log(`Created container "${containerName}"`);
    } else {
      context.log(`Container "${containerName}" already exists`);
    }

    context.log(`Uploading file: ${filename}`);
    const blockBlobClient = containerClient.getBlockBlobClient(filename);

    await blockBlobClient.uploadData(Buffer.from(fileBuffer), {
      blobHTTPHeaders: { blobContentType: "text/csv" },
    });

    return {
      status: 200,
      body: `Successfully uploaded "${filename}" to blob storage.`,
    };
  } catch (error) {
    context.error("Upload failed", error);
    return {
      status: 500,
      body: "Something went wrong during the file upload.",
    };
  }
}

app.http("uploadCSV", {
  methods: ["POST"],
  authLevel: "anonymous",
  handler: uploadCSV,
});
