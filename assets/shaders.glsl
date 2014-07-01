#ifdef PIXEL

extern vec2 translations;
extern number scale;
extern number   red_op_number;
extern number green_op_number;
extern number  blue_op_number;
extern number   red_op_args_number;
extern number green_op_args_number;
extern number  blue_op_args_number;

// list of operations which will be chosen by op_numbers 

// 8 bit xor
// modified from source found here:
// http://stackoverflow.com/questions/373262/how-do-you-implement-xor-using
float xor (float a, float b){
    float n = 1.0;
    float result = 0.0;
    int ai = int(a);
    int bi = int(b);
    float partial;
    //"profile does not support while"
    // therefore, we need to use a while loop it knows how to unroll.
    // might be unnecessary in future
    int i = 0;
    while(i < 8) {
        partial =  mod(float(ai - bi), 2.0);
        result += n * partial;

        ai /= 2;
        bi /= 2;
        n *= 2.0;
        i += 1;
    }
    float resultf = float(result);
    return resultf;
}

float and (float a, float b){
    float n = 1.0;
    float result = 0.0;
    int ai = int(a);
    int bi = int(b);
    float partial;
    //"profile does not support while"
    // therefore, we need to use a while loop it knows how to unroll.
    // might be unnecessary in future
    int i = 0;
    while(i < 8) {
        partial = mod(float(ai * bi), 2.0);
        result += n * partial;

        ai /= 2;
        bi /= 2;
        n *= 2.0;
        i += 1;
    }
    float resultf = float(result);
    return resultf;
}

float or (float a, float b){
    float n = 1.0;
    float result = 0.0;
    int ai = int(a);
    int bi = int(b);
    float partial;
    //"profile does not support while"
    // therefore, we need to use a while loop it knows how to unroll.
    // might be unnecessary in future
    int i = 0;
    while(i < 8) {
        partial = mod(float(ai + bi), 2.0) + mod(float(ai * bi), 2.0);
        result += n * partial;

        ai /= 2;
        bi /= 2;
        n *= 2.0;
        i += 1;
    }
    float resultf = float(result);
    return resultf;
}

float diff_mult (float a, float b){
    return (a - b) * (b - a);
}

float quot_add (float a, float b){
    return (a / b) + (b / a);
}
 
float mult (float a, float b){
    return a * b;
}

float add (float a, float b){
    return a + b;
}

// helper op application function
float  op_apply (float op_arg_a, float op_arg_b, float op_number){
    if (op_number <= 1.0){
        return mod( xor(op_arg_a, op_arg_b) / 256.0 * scale, 1.0 );
    }
    else if (op_number <= 2.0){
        return mod( and(op_arg_a, op_arg_b) / 256.0 * scale, 1.0 );
    }
    else if (op_number <= 3.0){
        return mod( or(op_arg_a, op_arg_b) / 256.0 * scale, 1.0 );
    }
    else if (op_number <= 4.0){
        return mod( diff_mult(op_arg_a, op_arg_b) / 256.0 * scale, 1.0 );
    }
    else if (op_number <= 5.0){
        return mod( quot_add(op_arg_a, op_arg_b) / 256.0 * scale, 1.0 );
    }
    else if (op_number <= 6.0){
        return mod( mult(op_arg_a, op_arg_b) / 256.0 * scale, 1.0 );
    }
    else {
        return mod( add(op_arg_a, op_arg_b) / 256.0 * scale, 1.0 );
    }
}

// helper arg calculation function

vec2 op_arg_calc (float op_arg_number, vec2 sc){
    if (op_arg_number <= 1.0) {
        return vec2(sc.x + translations[0], (love_ScreenSize.y - sc.y) + translations[1]); 
    }
    else if (op_arg_number <= 2.0) {
        return vec2(sc.x + translations[0], (love_ScreenSize.y - sc.y)); 
    }
    else if (op_arg_number <= 3.0) {
        return vec2(sc.x, (love_ScreenSize.y - sc.y) + translations[1]); 
    }
    else {
        return vec2(sc.x, (love_ScreenSize.y - sc.y)); 
    }
}


///////////////////////////////////

vec4 effect( vec4 color, Image texture, vec2 tc, vec2 sc )
{
    float red = 0.0;
    float green = 0.0;
    float blue = 0.0;

    vec2 red_op_args = op_arg_calc (red_op_args_number, sc);

    red = op_apply(red_op_args.x, red_op_args.y, red_op_number);
    
    vec2 green_op_args = op_arg_calc (green_op_args_number, sc);

    green = op_apply(green_op_args.x, green_op_args.y, green_op_number);
    
    vec2 blue_op_args = op_arg_calc (blue_op_args_number, sc);

    blue = op_apply(blue_op_args.x, blue_op_args.y, blue_op_number);
     
       
    return vec4(red, green, blue, color.a);
}
#endif

#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    return transform_projection * vertex_position;
}
#endif
