import { parse } from "@std/toml";
import * as path from "@std/path";

import type { Config, ResultItem, VerData } from "./types.ts";

async function getUpdateInfo(
  resultJsonPath: string,
  configTomlPath: string,
  repoRoot: string,
) {
  // Read result.json
  let resultJsonContent: string;
  try {
    resultJsonContent = await Deno.readTextFile(resultJsonPath);
  } catch (e) {
    console.error(`Error reading ${resultJsonPath}:`, e);
    Deno.exit(1);
  }

  let results: ResultItem[] | [];
  try {
    results = JSON.parse(resultJsonContent);
  } catch (e) {
    console.error("Error parsing result.json:", e);
    Deno.exit(1);
  }

  // Read config.toml
  let configTomlContent: string;
  try {
    configTomlContent = await Deno.readTextFile(configTomlPath);
  } catch (e) {
    console.error(`Error reading ${configTomlPath}:`, e);
    Deno.exit(1);
  }

  const config = parse(configTomlContent) as Config;

  // Read new_ver.json
  const newVerFilePath = path.join(
    repoRoot,
    "assets/nvchecker",
    config.__config__.newver,
  );
  let newVerContent: string;
  try {
    newVerContent = await Deno.readTextFile(newVerFilePath);
  } catch (e) {
    console.error(`Error reading ${newVerFilePath}:`, e);
    Deno.exit(1);
  }

  let newVerData: VerData;
  try {
    newVerData = JSON.parse(newVerContent);
  } catch (e) {
    console.error(`Error parsing ${config.__config__.newver}:`, e);
    Deno.exit(1);
  }

  // Process results
  if (results.length === 0) {
    console.warn("No results found in result.json");
    Deno.exit(0);
  }
  for (const item of results) {
    const name = item.name;
    const configItem = config[name];

    if (
      configItem.use_latest_release === true || configItem.use_max_tag === true
    ) {
      continue;
    }

    if (newVerData.data[name].revision === undefined) {
      console.error(
        `Error: 'revision' field missing for '${name}' in ${config.__config__.newver}.`,
      );
      Deno.exit(1);
    }

    item.newver = newVerData.data[name].revision;
  }

  return results;
}

async function triggerWorkflow(
  name: string,
  version: string,
  token: string,
  repo: string,
  ref: string,
) {
  const url =
    `https://api.github.com/repos/${repo}/actions/workflows/${name}.yml/dispatches`;
  const body = {
    ref: ref,
    inputs: {
      version: version,
    },
  };

  console.log(`Triggering workflow for ${name} version ${version}...`);

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Accept": "application/vnd.github.v3+json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (response.ok) {
    console.log(`Successfully triggered workflow for ${name}`);
  } else {
    console.error(
      `Failed to trigger workflow for ${name}: ${response.status} ${response.statusText}`,
    );
    const errorText = await response.text();
    console.error(`Error details: ${errorText}`);
  }
}

export { getUpdateInfo, triggerWorkflow };
