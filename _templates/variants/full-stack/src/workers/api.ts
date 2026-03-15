export interface Env {
  // Add bindings here
}

export default {
  async fetch(request: Request, _env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === '/api/health') {
      return Response.json({ status: 'ok' });
    }

    // All non-API routes are handled by the Assets binding (React frontend)
    return new Response('Not Found', { status: 404 });
  },
} satisfies ExportedHandler<Env>;
