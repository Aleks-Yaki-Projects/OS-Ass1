#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"

int main(int argc,char** argv){
    pause_system(10);
    fprintf(2, "hello world!\n");
    exit(0);
}
