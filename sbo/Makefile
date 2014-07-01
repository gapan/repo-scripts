SSH_HOST=salixos.org
SSH_PORT=22
SSH_USER=repo
SSH_TARGET_DIR=/home/repo/repo/sbo/14.1

all: 
	@echo "Nothing to make."

upload:
	@scp -P $(SSH_PORT) SBoADD \
		SBoEXCLUDE \
		SBoREPLACE \
		$(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)/

upload-scripts:
	@scp -P $(SSH_PORT) sync.sh \
		$(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)/.sync.sh
	@scp -P $(SSH_PORT) sb_dupes_req \
		$(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)/.sb_dupes_req
	@scp -P $(SSH_PORT) sb_adddeps \
		$(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)/.sb_adddeps
	@scp -P $(SSH_PORT) sb_replace \
		$(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)/.sb_replace

.PHONY: all upload upload-scripts
