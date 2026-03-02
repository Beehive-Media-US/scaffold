export interface Env {
  DB: D1Database;
  CACHE: KVNamespace;
  AGENT_CORE: Fetcher;
  // Add bindings here
}

export default {
  async fetch(request: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === '/health') {
      return Response.json({ status: 'ok' });
    }

    // Route to agent-core for AI requests
    if (url.pathname.startsWith('/agent/')) {
      return env.AGENT_CORE.fetch(request);
    }

    return new Response('Not Found', { status: 404 });
  },
} satisfies ExportedHandler<Env>;
