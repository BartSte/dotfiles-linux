#!/bin/env bash

if [[ $(hostname) == "bart-asus" ]]; then
    export DEEPSEEK_API_KEY AIDER_MODEL
    DEEPSEEK_API_KEY=$(rbw_get password deepseektoken)
    AIDER_MODEL=deepseek/deepseek-reasoner

elif [[ $(hostname) == "zbook" ]]; then
    export OPENAI_API_KEY AIDER_MODEL AIDER_WEAK_MODEL
    OPENAI_API_KEY=$(rbw_get password openai_token)
    AIDER_MODEL=gpt-5-codex
    AIDER_WEAK_MODEL=gpt-5-nano
fi
