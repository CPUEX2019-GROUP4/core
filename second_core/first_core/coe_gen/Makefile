TARGET=test_hoge.coe

$(TARGET): ./generator ../../../../../RunojiArchitecture/compiler/program.txt
	./generator > ../mem_init/$(TARGET)

generator: coe_generator.c
	gcc -o $@ $^
