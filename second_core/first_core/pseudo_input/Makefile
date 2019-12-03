TARGET=pseudo_input.coe

$(TARGET): ./generator
	./generator > ../mem_init/$(TARGET)

generator: pseudo_input_generator.c
	gcc -o $@ $^
