/*
 * This file implements the main function
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <getopt.h>

#include "../inc/msg.h"
#include "../inc/label.h"
#include "../inc/global.h"
#include "../inc/output.h"
#include "../obj/asm.tab.h"

// reference to linenumber supplied by flex/bison
extern int yylineno;
// reference to yyrestart function supplied by flex/bison
void yyrestart(FILE* inputfile);

// file variable definitions and initialization
FILE* f_in = 0;
FILE* f_out = 0;
FILE* f_map = 0;

/*
 * main function
 * argc: number of arguments
 * argv: arguments
 */
int main(int argc, char **argv) {
	// output filename
	char* output = 0;
	// mapfile filename
	char* map = 0;

	// index of command line argument
	int option_index = 0;
	// character of command line argument
	int c;

	static struct option long_options[] = { { "verbose", 0, 0, 0 }, {
			"autoalign", 0, 0, 0 }, { "fillbds", 0, 0, 0 }, {
			"continue-on-error", 0, 0, 0 }, { 0, 0, 0, 0 } };

	// reset flags
	verbose = 0;
	autoalign = 0;
	continueonerror = 0;
	errorhappened = 0;

	while (1) {
		// iterate through all command line options

		// reset option_index
		option_index = 0;

		// get next option
		c = getopt_long(argc, argv, "vm:o:", long_options, &option_index);
		if (c == -1)
			// no more options available, end loop
			break;

		// check which option it was
		switch (c) {
		case 0: // long option
			if (strcmp(long_options[option_index].name, "verbose") == 0) {
				// verbose flag
				verbose = 1;

			} else if (strcmp(long_options[option_index].name, "autoalign")
					== 0) {
				// auto-align flag
				autoalign = 1;

			} else if (strcmp(long_options[option_index].name, "fillbds")
					== 0) {
				// fill branch delay slot flag
				fillbds = 1;

			} else if (strcmp(long_options[option_index].name,
					"continue-on-error") == 0) {
				// continue on error flag
				continueonerror = 1;

			} else {
				// unknown option
				fprintf(stderr, "error: unknown command line option \"%s\"\n",
						long_options[option_index].name);
				destruct(EXIT_FAILURE);
			}
			break;

		case 'v':
			// verbose flag (short version)
			verbose = 1;
			break;

		case 'm':
			// map file
			map = (char*) optarg;
			break;

		case 'o':
			// output file
			output = (char*) optarg;
			break;

		default:
			// unknown option
			fprintf(stderr, "error: unknown command line option \"%s\"\n",
					long_options[option_index].name);
			destruct(EXIT_FAILURE);
		}
	}

	// Check non-option command line arguments
	if (optind < argc) {
		// one option still available (input)
		inputfile = argv[optind++];

		if (optind < argc) {
			// more than one option still available, only one input file supported
			fprintf(stderr, "too many input files specified.\n");
			destruct(EXIT_FAILURE);
		}

	} else {
		// no option available (no input file)
		fprintf(stderr, "no input file specified.\n");
		destruct(EXIT_FAILURE);
	}

	// Check if output file is specified
	if (output == 0) {
		// output file not specified
		fprintf(stderr, "no output file specified.\n");
		destruct(EXIT_FAILURE);
	}

	// Open all (specified) files

	// open input file (must be specified, is checked before)
	f_in = fopen(inputfile, "r");
	if (!f_in) {
		// could not open input file
		fprintf(stderr, "error: could not open input file %s\n", inputfile);
		perror(inputfile);
		destruct(EXIT_FAILURE);
	}

	// open output file (must be specified, is checked before)
	f_out = fopen(output, "w");
	if (!f_out) {
		// could not open output file
		fprintf(stderr, "error: could not open output file %s\n", output);
		perror(output);
		destruct(EXIT_FAILURE);
	}

	// open map file if specified
	if (map != 0) {
		// mapfile is specified
		f_map = fopen(map, "w");
		if (!f_map) {
			// could not open mapfile
			fprintf(stderr, "error: could not open map file %s\n", map);
			perror(map);
			destruct(EXIT_FAILURE);
		}
	}

	// reset variables
	address = 0;
	label_listhead = 0;

	// start parsing f_in - first run
	isfirstrun = 1;
	yyrestart(f_in);
	yyparse();

	// go back to first character in input file
	fseek(f_in, 0, SEEK_SET);
	yylineno = 1;

	// start parsing f_in - second run
	address = 0;
	isfirstrun = 0;
	yyrestart(f_in);
	yyparse();

	// fill last word
	if (address % 4 == 2) {
		output_instr16(nop16);
	}

	// destruction

	// final message
	if (verbose) {
		printf("%s:   : info: output written to %s.\n", inputfile, output);
	}

	// exit main
	if (!errorhappened) {
		// no error happened
		destruct(EXIT_SUCCESS);
	} else {
		// error happend in between
		destruct(EXIT_FAILURE);
	}

	return 0; // suppress warning, actual program exit in destruct
}

// destructor, closes programs and cleans up memory
// exitvalue: value for exit
void destruct(int exitvalue) {
	if (f_in) {
		fclose(f_in);
	}
	if (f_out) {
		fclose(f_out);
	}
	if (f_map) {
		fclose(f_map);
	}

	label_free();

	exit(exitvalue);
}
