import * as path from "@std/path";

import { parseArgs } from "@std/cli";
import { getUpdateInfo, triggerWorkflow } from "./utils.ts";

const scriptDir = path.dirname(path.fromFileUrl(import.meta.url));
const repoRoot = path.resolve(scriptDir, "../../");
const resultJsonPath = path.join(scriptDir, "result.json");
const configTomlPath = path.join(repoRoot, "assets/nvchecker/config.toml");

async function main() {
  const args = parseArgs(Deno.args, {
    string: ["token", "repo"],
    boolean: ["dry-run"],
    default: {
      repo: "MZWNET/actions",
    },
  });

  if (!args.token) {
    console.error("Error: --token is required.");
    Deno.exit(1);
  }

  const updateInfo = await getUpdateInfo(
    resultJsonPath,
    configTomlPath,
    repoRoot,
  );

  for (const item of updateInfo) {
    if (args["dry-run"]) {
      console.log(
        `[Dry Run] Would trigger workflow for ${item.name} with version ${item.newver}`,
      );
    } else {
      await triggerWorkflow(item.name, item.newver, args.token, args.repo, "master");
    }
  }
}

if (import.meta.main) {
  main();
}
