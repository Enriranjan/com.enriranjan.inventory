using System;

namespace EnriRanjan.Inventory
{
    /// <summary>
    /// Read-only snapshot of a single inventory slot: either empty or holding
    /// one item. Works for both struct and class ids, unlike Nullable&lt;TId&gt;.
    /// </summary>
    public readonly struct InventorySlot<TId> where TId : IEquatable<TId>
    {
        public static InventorySlot<TId> Empty => default;

        private readonly TId _item;

        public bool HasItem { get; }

        /// <summary>The item in the slot; throws when the slot is empty.</summary>
        public TId Item
        {
            get
            {
                if (!HasItem)
                {
                    throw new InvalidOperationException("The slot is empty.");
                }

                return _item;
            }
        }

        public InventorySlot(TId item)
        {
            _item = item;
            HasItem = true;
        }

        public bool TryGetItem(out TId item)
        {
            item = _item;
            return HasItem;
        }

        public override string ToString()
        {
            return HasItem ? _item.ToString() : "<empty>";
        }
    }
}
