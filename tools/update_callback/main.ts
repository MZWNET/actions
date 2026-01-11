import { parseArgs } from "@std/cli";
import { getUpdateInfo, triggerWorkflow } from "./utils.ts";

async function main() {
  const args = parseArgs(Deno.args, {
    string: ["config", "newver", "ref", "repo", "result", "token"],
    boolean: ["dry-run"],
    default: {
      "dry-run": false,
    },
  });

  if (
    !args.config || !args.newver || !args.ref || !args.repo || !args.result ||
    !args.token
  ) {
    console.error(
      "Error: params don't match. Required params: --config, --newver, --ref, --repo, --result, --token",
    );
    Deno.exit(1);
  }

  const updateInfo = await getUpdateInfo(
    args.result,
    args.config,
    args.newver,
  );

  for (const item of updateInfo) {
    if (args["dry-run"]) {
      console.log(
        `[Dry Run] Would trigger workflow for ${item.name} with version ${item.newver}`,
      );
    } else {
      await triggerWorkflow(
        item.name,
        item.newver,
        args.token,
        args.repo,
        "master",
      );
    }
  }
}

if (import.meta.main) {
  main();
}
