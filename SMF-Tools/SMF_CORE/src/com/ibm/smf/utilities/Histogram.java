/*                                                                   */
/* Copyright 2026 IBM Corp.                                          */
/*                                                                   */
/* Licensed under the Apache License, Version 2.0 (the "License");   */
/* you may not use this file except in compliance with the License.  */
/* You may obtain a copy of the License at                           */
/*                                                                   */
/* http://www.apache.org/licenses/LICENSE-2.0                        */
/*                                                                   */
/* Unless required by applicable law or agreed to in writing,        */
/* software distributed under the License is distributed on an       */
/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,      */
/* either express or implied. See the License for the specific       */
/* language governing permissions and limitations under the License. */
/*                                                                   */
package com.ibm.smf.utilities;

import java.util.Arrays;

import com.ibm.smf.format.SmfPrintStream;

/**
 * Prints a horizontal histogram for a set of longs grouped into bins.
 *
 * Example output (10 numbers, 5 bins):
 *
 *   1 -  3 | ++++  4
 *   3 -  5 | ++    2
 *   5 -  7 | +++   3
 *   7 -  9 | +     1
 *   9 - 11 | +     1
 */
public class Histogram {

    private final long[] data;
    private final int binCount;

    /**
     * @param data     the longs to histogram (must not be empty)
     * @param binCount how many bins to divide the range into
     */
    public Histogram(long[] data, int binCount) {
        if (data == null || data.length == 0) {
            throw new IllegalArgumentException("data must not be null or empty");
        }
        if (binCount < 1) {
            throw new IllegalArgumentException("binCount must be >= 1");
        }
        this.data = Arrays.copyOf(data, data.length);
        this.binCount = binCount;
    }

    /** Prints the histogram. */
    public void print(SmfPrintStream stream) {
        long min = Arrays.stream(data).min().getAsLong();
        long max = Arrays.stream(data).max().getAsLong();

        // When all values are identical, widen the range by 1 to avoid zero-width bins.
        if (max == min) {
            max = min + 1;
        }

        long range = max - min;
        int[] counts = new int[binCount];

        for (long value : data) {
            int bin = (int) ((value - min) * binCount / range);
            // Clamp the maximum value into the last bin.
            if (bin >= binCount) {
                bin = binCount - 1;
            }
            counts[bin]++;
        }

        int maxCount = Arrays.stream(counts).max().getAsInt();
        int barScale = 1;                // counts per '+' block
        int maxBarLen = 40;              // cap bar width at 40 blocks
        if (maxCount > maxBarLen) {
            barScale = (int) Math.ceil((double) maxCount / maxBarLen);
        }

        // Label width: wide enough for the largest boundary value.
        int labelWidth = String.valueOf(max).length();
        String labelFmt = "  %" + labelWidth + "d - %" + labelWidth + "d |";

        // Bin boundary step (ceiling division so bins cover the full range).
        long step = (range + binCount - 1) / binCount;

        stream.println("");
        for (int i = 0; i < binCount; i++) {
            long lo = min + (long) i * step;
            long hi = lo + step;
            String bar = "+".repeat((counts[i] + barScale - 1) / barScale);
            stream.println(String.format(labelFmt + " %-" + maxBarLen + "s  %d",
                    lo, hi, bar, counts[i]));
        }
        stream.println("");
        if (barScale > 1) {
            stream.println(String.format("  Each '+' block represents of up to %d value(s)%n", barScale));
        }
    }
}

// Made with IBM Bob
