module.exports = async (
  { github, context, TARGET_PREFIXES, KEEP_COUNT_MATCHED, KEEP_COUNT_OTHERS },
) => {
  const isDryRun = context.payload.inputs
    ? context.payload.inputs.dry_run === "true"
    : false;

  console.log(`Running Mode: ${isDryRun ? "DRY RUN" : "LIVE"}`);

  const allReleases = await github.paginate(github.rest.repos.listReleases, {
    owner: context.repo.owner,
    repo: context.repo.repo,
    per_page: 100,
  });

  console.log(`Total Releases fetched: ${allReleases.length}`);

  const groups = {};

  TARGET_PREFIXES.forEach((p) => groups[p] = []);
  groups["__OTHERS__"] = [];

  for (const release of allReleases) {
    if (release.draft) continue;

    let matched = false;
    for (const prefix of TARGET_PREFIXES) {
      if (release.tag_name.startsWith(prefix)) {
        groups[prefix].push(release);
        matched = true;
        break;
      }
    }
    if (!matched) {
      groups["__OTHERS__"].push(release);
    }
  }

  let releasesToDelete = [];

  for (const prefix of TARGET_PREFIXES) {
    const list = groups[prefix];
    list.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    if (list.length > KEEP_COUNT_MATCHED) {
      const toRemove = list.slice(KEEP_COUNT_MATCHED);
      releasesToDelete = releasesToDelete.concat(toRemove);
      console.log(
        `[Prefix ${prefix}] Found ${list.length}, will delete the oldest ${toRemove.length} (keeping first ${KEEP_COUNT_MATCHED})`,
      );
    } else {
      console.log(
        `[Prefix ${prefix}] Only found ${list.length}, no deletion needed.`,
      );
    }
  }

  const othersList = groups["__OTHERS__"];
  othersList.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  if (othersList.length > KEEP_COUNT_OTHERS) {
    const toRemove = othersList.slice(KEEP_COUNT_OTHERS);
    releasesToDelete = releasesToDelete.concat(toRemove);
    console.log(
      `[Others] Found ${othersList.length}, will delete the oldest ${toRemove.length} (keeping latest ${KEEP_COUNT_OTHERS})`,
    );
  } else {
    ``;
    console.log(
      `[Others] Only found ${othersList.length}, no deletion needed.`,
    );
  }

  if (releasesToDelete.length === 0) {
    console.log("No Releases to delete. Exiting.");
    return;
  }

  for (const release of releasesToDelete) {
    const tag = release.tag_name;
    console.log(`Processing: ${tag} (ID: ${release.id})...`);

    if (!isDryRun) {
      try {
        await github.rest.repos.deleteRelease({
          owner: context.repo.owner,
          repo: context.repo.repo,
          release_id: release.id,
        });

        try {
          await github.rest.git.deleteRef({
            owner: context.repo.owner,
            repo: context.repo.repo,
            ref: `tags/${tag}`,
          });
          console.log(`✅ Deleted Release and Tag: ${tag}`);
        } catch (tagErr) {
          console.log(
            `⚠️ Release ${tag} deleted, but failed to delete Tag (might not exist): ${tagErr.message}`,
          );
        }
      } catch (err) {
        console.error(`❌ Failed to delete ${tag}: ${err.message}`);
      }
    } else {
      console.log(`[DRY RUN] Will delete Release: ${tag} and Tag: tags/${tag}`);
    }
  }
};
