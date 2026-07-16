using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace EnriRanjan.Inventory
{
    /// <summary>
    /// Slot-based inventory over opaque item ids: fixed capacity, one item per
    /// slot, no stacking. Ids are whatever the application decides; the system
    /// never interprets them. Duplicated ids are allowed - vetoing duplicates
    /// is an application-layer rule. Items keep their slot: removing frees the
    /// slot and a later add takes the first free slot.
    /// </summary>
    public sealed class InventorySystem<TId> where TId : IEquatable<TId>
    {
        private readonly InventorySlot<TId>[] _slots;
        private readonly ReadOnlyCollection<InventorySlot<TId>> _slotsView;

        /// <summary>Raised after an item enters a slot: (item, slot index).</summary>
        public event Action<TId, int> ItemAdded;

        /// <summary>Raised after an item leaves a slot: (item, slot index).</summary>
        public event Action<TId, int> ItemRemoved;

        public int Capacity => _slots.Length;

        public int Count { get; private set; }

        public bool IsFull => Count == Capacity;

        /// <summary>Live read-only view of every slot, empty ones included.</summary>
        public IReadOnlyList<InventorySlot<TId>> Slots => _slotsView;

        public InventorySystem(int capacity)
        {
            if (capacity <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(capacity), capacity, "Capacity must be positive.");
            }

            _slots = new InventorySlot<TId>[capacity];
            _slotsView = new ReadOnlyCollection<InventorySlot<TId>>(_slots);
        }

        /// <summary>
        /// Puts the item in the first free slot. Returns false (and raises no
        /// event) when the inventory is full.
        /// </summary>
        public bool TryAdd(TId id, out int slot)
        {
            if (id == null)
            {
                throw new ArgumentNullException(nameof(id));
            }

            for (int i = 0; i < _slots.Length; i++)
            {
                if (_slots[i].HasItem)
                {
                    continue;
                }

                _slots[i] = new InventorySlot<TId>(id);
                Count++;
                slot = i;
                ItemAdded?.Invoke(id, i);
                return true;
            }

            slot = -1;
            return false;
        }

        /// <summary>
        /// Removes the first occurrence of the id. Returns false when the
        /// inventory does not contain it.
        /// </summary>
        public bool TryRemove(TId id)
        {
            int slot = IndexOf(id);
            return slot >= 0 && TryRemoveAt(slot);
        }

        /// <summary>Empties the slot. Returns false when it was already empty.</summary>
        public bool TryRemoveAt(int slot)
        {
            if (slot < 0 || slot >= _slots.Length)
            {
                throw new ArgumentOutOfRangeException(nameof(slot), slot, $"Slot must be in [0, {_slots.Length - 1}].");
            }

            if (!_slots[slot].TryGetItem(out TId item))
            {
                return false;
            }

            _slots[slot] = InventorySlot<TId>.Empty;
            Count--;
            ItemRemoved?.Invoke(item, slot);
            return true;
        }

        public bool Contains(TId id)
        {
            return IndexOf(id) >= 0;
        }

        private int IndexOf(TId id)
        {
            if (id == null)
            {
                throw new ArgumentNullException(nameof(id));
            }

            for (int i = 0; i < _slots.Length; i++)
            {
                if (_slots[i].TryGetItem(out TId item) && item.Equals(id))
                {
                    return i;
                }
            }

            return -1;
        }
    }
}
