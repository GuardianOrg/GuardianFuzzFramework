# Default instance type
DEFAULT_INSTANCE = s-4vcpu-8gb-intel

# Default target when you just run 'make'
help:
	@echo "Available targets:"
	@echo "  cloud JOB=<job_index> [INSTANCE=<instance_type>] - Run cloud execution with specified job and instance"
	@echo "  clean - Remove generated output directory"

# Main target for cloud execution
cloud:
	@if [ "$(JOB)" = "" ]; then \
		echo "Usage: make cloud JOB=<job_index> [INSTANCE=<instance_type>]"; \
		echo "Example: make cloud JOB=2"; \
		echo "Example: make cloud JOB=2 INSTANCE=s-8vcpu-16gb-intel"; \
		exit 1; \
	fi
	@INSTANCE=$(or $(INSTANCE),$(DEFAULT_INSTANCE)); \
	echo "Preparing Echidna corpus from job $(JOB)..."; \
	mkdir -p output src output/echidna-corpus; \
	touch src/strings.sol; \
	rm -rf output/echidna-corpus; \
	cp -r cloudexec/job-$(JOB)/echidna-corpus output/echidna-corpus; \
	echo "Launching cloudexec with instance $$INSTANCE..."; \
	cloudexec launch --size $$INSTANCE

# Clean up generated files
clean:
	rm -rf output