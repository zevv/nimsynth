
import math


proc read1(tab: openArray[float], indexIn: float): float =
	let
    index = indexIn - indexIn.floor
    p = index * tab.len + 0.5
    i = p mod tab.len;
  return tab[i];


proc read2(tab: openArray[float], indexIn: float): float =
{
  let
    index = indexIn - indexIn.floor;
    p = index * tab.len;
    size_t i = p;
    size_t j = i+1;
    if(j >= size) j -= size;
    float a0 = p - i;
    float a1 = 1.0 - a0;

    float v0 = tab[i];
    float v1 = tab[j];

    return v0 * a1 + v1 * a0;


