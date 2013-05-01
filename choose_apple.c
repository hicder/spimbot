int x = APPLE_CREATED_X;
int y = APLLE_CREATED_Y;
int a = privateapplex;
int b = privateappley;

int s = HEAD_X;
int t = HEAD_Y;
dis1 = abs(s-x) + abs(t - y);
dis2 = abs(s-a) + abs(t - b);
if(dis1 < dis2){
	privateapplex = APPLE_CREATED_X;
	privateappley = APPLE_CREATED_Y;
}
