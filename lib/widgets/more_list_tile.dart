import 'package:flutter/material.dart';

typedef RatingEvent(int index);

class RatingListTile extends StatelessWidget {
  final Widget title;
  final IconData icon;
  final int count;
  final int selected;
  final Color color;
  final RatingEvent onRating;

  const RatingListTile({
    Key key,
    this.title,
    this.icon,
    this.count,
    this.selected,
    this.color,
    this.onRating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      trailing: Wrap(
        children: List.generate(
          count,
          (index) => IconButton(
            icon: Icon(
              icon,
              color: index < selected ? color : Colors.grey,
            ),
            onPressed: () {
              return onRating?.call(index + 1);
            },
          ),
        ),
      ),
    );
  }
}

typedef VoteEvent(int index);

class VoteListTile extends StatelessWidget {
  final Widget title;
  final List<IconData> icons;
  final int selected;
  final Color color;
  final VoteEvent onVote;

  const VoteListTile({
    Key key,
    this.title,
    this.icons,
    this.selected,
    this.color,
    this.onVote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      trailing: Wrap(
        children: List.generate(
          icons.length,
          (index) => IconButton(
            icon: Icon(
              icons[index],
              color: selected == index + 1 ? color : Colors.grey,
            ),
            color: Colors.grey,
            onPressed: () {
              onVote?.call(index + 1);
            },
          ),
        ),
      ),
    );
  }
}