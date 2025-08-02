import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import * as bcrypt from "bcryptjs"
import * as jwt from "jsonwebtoken"
import {container} from "../db/cosmosClient"
import * as dotenv from "dotenv"

dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET_KEY || "your-very-secure-dev-secret";


export async function userLogin(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    const { email, password } = await request.json() as { email?: string, password?: string};


    if (!email || !password) {
        return {
            status: 400,
            body: "email and password are required"
        }
    }  

    const querySpec = {
        query: "SELECT * FROM c WHERE c.email = @email",
        parameters: [{ name: "@email", value: email }]
    }

    const { resources: items } = await container.items.query(querySpec).fetchAll();
    const user = items[0];

    if (!user) {
        return {
            status: 401,
            body: "Invalid email or password"
        };
    }
    
    const isValidPassword = await bcrypt.compare(password, user.password);

    if (!isValidPassword) {
        return {
            status: 401,
            body: "Invalid password"
        };
    }    

    const token = jwt.sign(
        { id: user.id, email: user.email},
        JWT_SECRET,
        { expiresIn: "1h" }
    )

    return {
        status: 200,
        jsonBody: { message: "Login successful", token, user }
    };
};

app.http('userLogin', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: userLogin
});
