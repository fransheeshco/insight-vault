import { CosmosClient } from "@azure/cosmos";

import * as dotenv from "dotenv"
dotenv.config();

const endpoint = process.env.COSMOS_DB_ENDPOINT;
const key = process.env.COSMOS_DB_KEY!;

const client = new CosmosClient({endpoint: endpoint, key: key});
const database = client.database("ivfreedbx6zud42lxvsu2");
const container = database.container("ivfreeuserx6zud42lxvsu2");

export { container, database };