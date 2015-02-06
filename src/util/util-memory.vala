/* Copyright 2014-2015 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace California.Memory {

/**
 * A rotating-XOR hash that can be used to hash memory buffers of any size.
 */
public uint hash(void *ptr, size_t bytes) {
    if (bytes == 0)
        return 0;
    
    uint8 *u8 = (uint8 *) ptr;
    
    // initialize hash to first byte value and then rotate-XOR from there
    uint hash = *u8;
    for (int ctr = 1; ctr < bytes; ctr++)
        hash = (hash << 4) ^ (hash >> 28) ^ (*u8++);
    
    return hash;
}

}

