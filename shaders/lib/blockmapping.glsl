#ifndef _INCLUDE_BLOCKMAPPING_GLSL_
#define _INCLUDE_BLOCKMAPPING_GLSL_

bool isSimpleVoxel(int ID)  { return ID == 2; }
bool isEntity(int ID)       { return ID == 0; }
bool isLeavesType(int ID)   { return (ID % 64) == 3; }
bool isGlassType(int ID)    { return (ID % 64) == 4; }
bool isEmissive(int ID)     { return (ID & 64) > 0 && (ID != 250); }
bool isWater(int ID)        { return ID == 21; }
bool isBackFaceType(int ID) { return ID == 3 || ID == 4; }
bool isSapling(int ID)      { return ID == 5; }
bool isTallGrass(int ID)    { return ID == 7; }

#endif
