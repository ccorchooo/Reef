import QtQuick
import qs.theme

// A row of M3 Expressive buttons sharing one width (MOTION.md → Button groups).
// Each child spans `span` of `columns` equal cells. Pressing one widens it by press-grow
// while the others give up that width between them (spatial-fast, so it overshoots a
// little); on release they spring back and the pressed one settles into its new shape.
// Reduce motion turns the widening off.
//
//   ButtonGroup { width: parent.width; columns: 4; Tile { span: 2 } Tile { span: 2 } }
//
// Children opt in with `property int span`, and read their width from widthOf(this)
// (Tile does both, and reports itself in `pressedItem` while pressed).
Row {
    id: root

    property int columns: 4
    property Item pressedItem: null

    spacing: Tokens.space2

    readonly property real cell: (width - spacing * (columns - 1)) / columns

    function widthOf(item) {
        const span = item.span ?? 1;
        const base = cell * span + spacing * (span - 1);
        const p = pressedItem;
        if (!p || !p.visible || Motion.reduceMotion)
            return base;
        let others = 0;
        for (let i = 0; i < children.length; i++) {
            const c = children[i];
            // Only buttons count (not a Repeater that makes them).
            if (c.visible && c !== p && c.span !== undefined)
                others += c.span ?? 1;
        }
        if (others === 0)
            return base;
        return item === p ? base + Tokens.pressGrow : base - Tokens.pressGrow * span / others;
    }
}
