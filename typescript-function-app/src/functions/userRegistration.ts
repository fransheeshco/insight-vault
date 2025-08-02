import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import {container} from "../db/cosmosClient"
import * as bcryptjs from 'bcryptjs'

export async function userRegistration(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    const { email, password } = await request.json() as { email?: string, password?: string };

    if (!email || !password) {
        return {
            status: 400,
            body: "Username and password are required"
        };
    }

    const hashed_password = bcryptjs.hashSync(password, 10);

    try {
        const newUser = {
            email: email,
            password: hashed_password,
        };

        const { resource } = await container.items.create(newUser);

        return {
            status: 201,
            jsonBody: {
                message: "User registered successfully",
                user: resource,
            },
        };
    } catch (err) {
        context.log(`❌ Error registering user: ${JSON.stringify(err)}`);
        return {
            status: 500,
            body: err,
        };
    }
}


app.http('userRegistration', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: userRegistration
});
