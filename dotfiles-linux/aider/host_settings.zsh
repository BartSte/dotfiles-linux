#!/bin/env bash

if [[ $(hostname) == "bart-asus" ]]; then
    export DEEPSEEK_API_KEY AIDER_MODEL
    DEEPSEEK_API_KEY=$(rbw_get password deepseektoken)
    AIDER_MODEL=deepseek/deepseek-chat

elif [[ $(hostname) == "zbook" ]]; then
    export OPENAI_API_KEY AIDER_MODEL
    OPENAI_API_KEY=$(rbw_get password openai_token)
    AIDER_MODEL=o3-mini

fi
