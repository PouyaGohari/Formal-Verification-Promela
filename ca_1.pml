#define PACKET_SIZE 4;
#define RANDOM	(seed * 3 + 14) % 100

int NODES = 3;
chan bluetooth[NODES] = [0] of {int};
chan BUS[NODES] = [0] of {int, int, int, int};
chan Collector_BUS[NODES] = [0] of {int, int, int, int};
bool reciveFromBus[NODES] = false;
bool nodeCanSent[NODES] = false;
int seed = 0;	


proctype Sensor1(int i) {
	do
	:: seed == 100 -> seed = 0;
	:: else -> bluetooth[i]!RANDOM; seed++;
	od
}

proctype Sensor2(int i) {
	do
	:: seed == 100 -> seed = 0;
	:: else -> bluetooth[i]!RANDOM; seed++;
	od
}

proctype CPU(int i) {
	int sensorData[4] = 0;
	int receivedData = 0;
	do
	:: receivedData < PACKET_SIZE -> bluetooth[i]?sensorData[receivedData];
			   receivedData++;
	:: else -> BUS[i]!sensorData[0],sensorData[1],sensorData[2],sensorData[3];
			   receivedData = 0;
	od
}

proctype Radio(int i) {
	int comData[4];
	do
	:: reciveFromBus[i] == false -> BUS[i]?comData[0],comData[1],comData[2],comData[3];
									 reciveFromBus[i] = true;
	:: reciveFromBus[i] == true  -> Collector_BUS[i]!comData[0],comData[1],comData[2],comData[3];
									 reciveFromBus[i] = false;
	od
}

active proctype Collector() {
	int comData[4];
	int count = 0;
	int defindeOnce = 0;
	do
	:: defindeOnce == 0 && count < NODES ->
									 run Sensor1(count);
									 run Sensor2(count);
									 run CPU(count);
									 run Radio(count);
									 count ++;
	:: nodeCanSent[count] == false && defindeOnce == 1 && count < NODES -> 
									Collector_BUS[count]?comData[0],comData[1],comData[2],comData[3];
									nodeCanSent[count] = true;
									count ++;
																			 
	:: count == NODES -> atomic{do
						:: count > 0 -> nodeCanSent[count-1] = false;count --;
						:: else -> count = 0;
								   defindeOnce = 1;
								   break;
						od}
	od
}

