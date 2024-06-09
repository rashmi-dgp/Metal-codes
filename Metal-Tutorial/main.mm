//
//  main.mm
//  MetalTutorial
//

#include "mtl_engine.hpp"
using namespace std;
int main() {
    @autoreleasepool {
        cout<<"Hello world \n";
        MTLEngine engine;
        engine.init();
        engine.run();
        engine.cleanup();
    }
    
    return 0;
}
