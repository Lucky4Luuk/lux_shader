//Thanks BruceKnowsHow (modified from https://github.com/BruceKnowsHow/Octray/blob/master/shaders/BlockMappings.glsl)

#if MC_VERSION >= 11300
	int BackPortID(int ID) {
		if (ID == -1) return 1; // un-assigned blocks in 1.13+

		return ID;
	}
#else
	int BackPortID(int ID) {
		return ID;
	}
#endif

bool isSimpleVoxel(int ID)  { return ID == 2; }
bool isEntity(int ID)       { return ID == 0; }
bool isLeavesType(int ID)   { return (ID % 64) == 3; }
bool isGlassType(int ID)    { return (ID % 64) == 4; }
bool isEmissive(int ID)     { return (ID & 64) > 0 && (ID != 250); }
bool isWater(int ID)        { return ID == 21; }
bool isBackFaceType(int ID) { return ID == 3 || ID == 4; }
bool isSapling(int ID)      { return ID == 5; }
bool isTallGrass(int ID)    { return ID == 7; }
