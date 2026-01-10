type Config = {
  __config__: {
    oldver: string;
    newver: string;
  };
} & {
  [key: string]: {
    source: "github" | "gitlab" | "gitea";
    github?: string;
    gitlab?: string;
    gitea?: string;
    host?: string;
    use_latest_release?: boolean;
    use_max_tag?: boolean;
  };
};

interface ResultItem {
  delta: string;
  name: string;
  newver: string;
  oldver: null | string;
}

interface VerData {
  version: number;
  data: {
    [key: string]: {
      version: string;
      gitref?: string;
      revision?: string;
      url: string;
    };
  };
}

export type { Config, ResultItem, VerData };
