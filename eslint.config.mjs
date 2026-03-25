// eslint.config.js
import tseslint from "@typescript-eslint/eslint-plugin";
import parser from "@typescript-eslint/parser";
import eslint from "@eslint/js";
import globals from "globals";

export default [
  {
    files: ["src/**/*.ts"],
    ignores: ["dist/**", "node_modules/**"],

    languageOptions: {
      parser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
        project: "./tsconfig.json",
      },
      globals: globals.node,
    },

    plugins: {
      "@typescript-eslint": tseslint,
    },

    rules: {
      // Base ESLint recommended rules
      ...eslint.configs.recommended.rules,

      // TypeScript recommended rules
      ...tseslint.configs.recommended.rules,

      // Custom rules for NestJS backend
      "@typescript-eslint/explicit-module-boundary-types": "off",
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-unused-vars": [
        "warn",
        { argsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/no-magic-numbers": [
        "warn",
        { ignore: [0, 1], ignoreEnums: true, ignoreNumericLiteralTypes: true },
      ],
      "@typescript-eslint/prefer-readonly": "warn",
      "@typescript-eslint/no-unnecessary-condition": "warn",
      "@typescript-eslint/consistent-type-imports": "warn",
    },
  },
];