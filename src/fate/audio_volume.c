/* Independently reconstructed FATE positional volume.
 * Each signed axis delta is square-rooted separately; this is not distance.
 */
extern short audio_listener_index;
extern long audio_listener_x[], audio_listener_y[];
extern long ksqrt(long);

unsigned long audio_volume(long x,long y)
{
 unsigned long distance;
 short volume;
 x=ksqrt(audio_listener_x[audio_listener_index]-x);
 y=ksqrt(audio_listener_y[audio_listener_index]-y);
 distance=(x*x+y*y)*2;
 if(distance>32767)distance=32767;
 volume=32767-distance;
 return volume | (volume<<16);
}
