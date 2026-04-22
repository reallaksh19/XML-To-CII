FC = gfortran
FFLAGS = -O2 -Wall

OBJS = cii_model_types.o write_coords.o write_hanger_miscel.o write_nodename.o
TARGET = test_harness

all: $(TARGET)

$(TARGET): $(OBJS) main.o
	$(FC) $(FFLAGS) -o $@ $^

%.o: %.f90
	$(FC) $(FFLAGS) -c $<

clean:
	rm -f *.o *.mod $(TARGET) test_output.CII
