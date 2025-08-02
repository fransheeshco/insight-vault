import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { BlobServiceClient } from "@azure/storage-blob";
import * as dotenv from "dotenv";
import * as jwt from "jsonwebtoken";

dotenv.config();

export async function uploadCSV(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  try {
    // ✅ Step 1: Get and verify the JWT
    const authHeader = request.headers.get("authorization") || "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : null;

    if (!token) {
      return {
        status: 401,
        body: "Unauthorized: No token provided.",
      };
    }

    const jwtSecret = process.env.JWT_SECRET_KEY;
    if (!jwtSecret) {
      return {
        status: 500,
        body: "Server configuration error: JWT secret is missing.",
      };
    }

    let decoded: any;
    try {
      decoded = jwt.verify(token, jwtSecret);
      context.log("✅ JWT verified:", decoded);
    } catch (err) {
      context.error("JWT verification failed:", err);
      return {
        status: 401,
        body: "Unauthorized: Invalid token.",
      };
    }

    const userId = decoded.userId || decoded.email || "anonymous";
    if (!userId) {
      return {
        status: 400,
        body: "Invalid token: Missing user identifier.",
      };
    }

    // ✅ Step 2: Read file and filename
    const fileBuffer = await request.arrayBuffer();
    const filename = request.query.get("filename") || request.headers.get("x-filename");

    if (!filename || !fileBuffer) {
      return {
        status: 400,
        body: "Missing file or filename. Please include a file and filename query/header.",
      };
    }

    // ✅ Step 3: Upload to Azure Blob Storage under user's folder
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

    const createContainerResponse = await containerClient.createIfNotExists();
    if (createContainerResponse.succeeded) {
      context.log(`🪣 Created container "${containerName}"`);
    } else {
      context.log(`ℹ️ Container "${containerName}" already exists`);
    }

    // 👇 Define path like: userId/filename.csv
    const blobName = `${userId}/${filename}`;
    const blockBlobClient = containerClient.getBlockBlobClient(blobName);

    context.log(`📤 Uploading file: ${blobName}`);
    await blockBlobClient.uploadData(Buffer.from(fileBuffer), {
      blobHTTPHeaders: { blobContentType: "text/csv" },
    });

    return {
      status: 200,
      body: `✅ Successfully uploaded "${filename}" under "${userId}" folder.`,
    };
  } catch (error) {
    context.error("❌ Upload failed", error);
    return {
      status: 500,
      body: "Something went wrong during the file upload.",
    };
  }
}

app.http("uploadCSV", {
  methods: ["POST"],
  authLevel: "anonymous", // Still allow access if token is manually verified
  handler: uploadCSV,
});
