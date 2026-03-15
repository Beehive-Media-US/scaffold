import { createAgent } from './agent.js';

const agent = createAgent();

async function main(): Promise<void> {
  // TODO: configure server/runner entrypoint
  console.log('Starting {{PROJECT_NAME}}...');
  await agent.run();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
