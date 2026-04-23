FC = gfortran
FFLAGS = -O2 -Wall

OBJS = cii_model_types.o write_coords.o write_hanger_miscel.o write_nodename.o
TARGET = test_harness

all: $(TARGET)

$(TARGET): $(OBJS) main.o
	$(FC) $(FFLAGS) -o $@ $^

%.o: %.f90
	$(FC) $(FFLAGS) -c $<

write_nodename.o: cii_model_types.o
write_hanger_miscel.o: cii_model_types.o
main.o: cii_model_types.o write_nodename.o write_hanger_miscel.o write_coords.o

clean:
	rm -f *.o *.mod $(TARGET) test_output.CII
